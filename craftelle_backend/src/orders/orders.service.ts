import { BadRequestException, Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Order, OrderDocument } from 'src/shared/schema/order.schema';
import { CreateOrderDto, SubmitQuoteDto, PayQuoteDto } from './dto/create-order.dto';
import { PaystackService } from 'src/paystack/paystack.service';
import { EmailService } from 'src/email/email.service';
import { NotificationService } from 'src/notification/notification.service';

@Injectable()
export class OrderService {
  constructor(
    @InjectModel(Order.name) private orderDB: Model<OrderDocument>,
    private readonly paystackService: PaystackService,
    private readonly emailService: EmailService,
    private readonly notificationService: NotificationService,
  ) {}

  async createOrder(createOrderDto: CreateOrderDto) {
    try {
      // Normalize wishListItems: handle both plain strings and structured objects
      const normalizedWishList = (createOrderDto.wishListItems || []).map(
        (item) =>
          typeof item === 'string'
            ? { text: item, specifications: '' }
            : {
                text: item.text || '',
                specifications: item.specifications || '',
              },
      );

      const hasExtras = normalizedWishList.length > 0;

      // If order has extras, it requires a quote — skip payment verification
      if (!hasExtras && createOrderDto.paymentReference) {
        const verifyData = await this.paystackService.verifyTransaction(
          createOrderDto.paymentReference,
        );

        const paystackStatus = verifyData?.data?.status;
        const paidAmountPesewas = verifyData?.data?.amount;
        const expectedAmountPesewas = Math.round(
          (createOrderDto.totalPrice || 0) * 100,
        );

        if (paystackStatus !== 'success') {
          throw new BadRequestException(
            `Payment not successful. Paystack status: ${paystackStatus}`,
          );
        }

        if (paidAmountPesewas !== expectedAmountPesewas) {
          throw new BadRequestException(
            `Payment amount mismatch. Paid: GHS ${(paidAmountPesewas / 100).toFixed(2)}, Expected: GHS ${(expectedAmountPesewas / 100).toFixed(2)}. You must pay the exact order amount.`,
          );
        }
      }

      const newOrder = new this.orderDB({
        customerEmail: createOrderDto.customerEmail,
        items: createOrderDto.items || [],
        wishListItems: normalizedWishList,
        totalPrice: createOrderDto.totalPrice || 0,
        status: 'Pending',
        deliveryCity: createOrderDto.deliveryCity || '',
        deliveryRegion: createOrderDto.deliveryRegion || '',
        deliveryAddress: createOrderDto.deliveryAddress || '',
        deliveryLatitude: createOrderDto.deliveryLatitude || null,
        deliveryLongitude: createOrderDto.deliveryLongitude || null,
        customerPhone: createOrderDto.customerPhone || '',
        paymentStatus: hasExtras ? 'Pending' : (createOrderDto.paymentStatus || 'Pending'),
        paymentReference: hasExtras ? '' : (createOrderDto.paymentReference || ''),
        requiresQuote: hasExtras,
        quoteStatus: hasExtras ? 'pending' : 'none',
      });

      await newOrder.save();

      // Only send receipt for non-quote orders (paid immediately)
      if (!hasExtras) {
        this.emailService.sendOrderReceiptEmail(newOrder.toObject()).catch((err) => {
          console.error('Failed to send order receipt email:', err);
        });
      }

      return {
        message: hasExtras
          ? 'Order submitted! The seller will review and quote your extras.'
          : 'Order placed successfully',
        success: true,
        result: newOrder,
      };
    } catch (error) {
      throw new BadRequestException(error.message);
    }
  }

  async submitQuote(orderId: string, submitQuoteDto: SubmitQuoteDto) {
    try {
      const order = await this.orderDB.findById(orderId);
      if (!order) throw new BadRequestException('Order not found');
      if (order.quoteStatus !== 'pending') {
        throw new BadRequestException(`Cannot quote an order with status: ${order.quoteStatus}`);
      }

      // Update each wishListItem with the quoted price
      const updatedWishList = order.wishListItems.map((existing) => {
        const quoted = submitQuoteDto.quotedWishListItems.find(
          (q) => q.text === existing.text,
        );
        return {
          text: existing.text,
          specifications: existing.specifications,
          quotedPrice: quoted ? quoted.quotedPrice : null,
        };
      });

      const quotedExtrasTotal = updatedWishList.reduce(
        (sum, item) => sum + (item.quotedPrice || 0), 0,
      );

      // Basket items total
      const basketTotal = (order.items || []).reduce(
        (sum, item) => sum + (item.price || 0) * (item.quantity || 1), 0,
      );

      const grandTotal = basketTotal + quotedExtrasTotal;

      order.wishListItems = updatedWishList as any;
      order.quotedExtrasTotal = quotedExtrasTotal;
      order.totalPrice = grandTotal;
      order.quoteStatus = 'quoted';
      order.quotedAt = new Date();
      await order.save();

      // Send quote email with PDF (async, non-blocking)
      this.emailService.sendQuoteEmail(order.toObject()).catch((err) => {
        console.error('Failed to send quote email:', err);
      });

      // Send push notification to customer
      this.notificationService.sendPushToUser(
        order.customerEmail,
        'Craftelle - Quote Ready',
        `Your extras have been priced! Total: GHS ${grandTotal.toLocaleString()}. Open the app to review and pay.`,
      ).catch((err) => {
        console.error('Failed to send quote push notification:', err);
      });

      return {
        message: 'Quote submitted successfully',
        success: true,
        result: order,
      };
    } catch (error) {
      throw new BadRequestException(error.message);
    }
  }

  async payQuote(orderId: string, payQuoteDto: PayQuoteDto) {
    try {
      const order = await this.orderDB.findById(orderId);
      if (!order) throw new BadRequestException('Order not found');
      if (order.quoteStatus !== 'quoted') {
        throw new BadRequestException(`Cannot pay an order with quote status: ${order.quoteStatus}`);
      }

      // Verify Paystack payment
      const verifyData = await this.paystackService.verifyTransaction(
        payQuoteDto.paymentReference,
      );
      const paystackStatus = verifyData?.data?.status;
      const paidAmountPesewas = verifyData?.data?.amount;
      const expectedAmountPesewas = Math.round((order.totalPrice || 0) * 100);

      if (paystackStatus !== 'success') {
        throw new BadRequestException(
          `Payment not successful. Paystack status: ${paystackStatus}`,
        );
      }

      if (paidAmountPesewas !== expectedAmountPesewas) {
        throw new BadRequestException(
          `Payment amount mismatch. Paid: GHS ${(paidAmountPesewas / 100).toFixed(2)}, Expected: GHS ${(expectedAmountPesewas / 100).toFixed(2)}.`,
        );
      }

      order.paymentStatus = 'Paid';
      order.paymentReference = payQuoteDto.paymentReference;
      order.quoteStatus = 'paid';
      await order.save();

      // Send final invoice to both customer and seller (async)
      this.emailService.sendFinalInvoiceEmail(order.toObject()).catch((err) => {
        console.error('Failed to send final invoice email:', err);
      });

      return {
        message: 'Payment confirmed! Invoice sent to your email.',
        success: true,
        result: order,
      };
    } catch (error) {
      throw new BadRequestException(error.message);
    }
  }

  async getOrdersByCustomer(customerEmail: string) {
    try {
      const orders = await this.orderDB
        .find({ customerEmail })
        .sort({ createdAt: -1 });
      return {
        message: 'Orders retrieved successfully',
        success: true,
        result: orders,
      };
    } catch (error) {
      throw new BadRequestException(error.message);
    }
  }

  async getOrdersBySeller(sellerEmail: string) {
    try {
      const orders = await this.orderDB
        .find({ 'items.sellerEmail': sellerEmail })
        .sort({ createdAt: -1 });
      return {
        message: 'Seller orders retrieved successfully',
        success: true,
        result: orders,
      };
    } catch (error) {
      throw new BadRequestException(error.message);
    }
  }

  async getAllOrders() {
    try {
      const orders = await this.orderDB.find().sort({ createdAt: -1 });
      return {
        message: 'Orders retrieved successfully',
        success: true,
        result: orders,
      };
    } catch (error) {
      throw new BadRequestException(error.message);
    }
  }

  async updateOrderStatus(id: string, orderStatus: string) {
    try {
      const updated = await this.orderDB.findByIdAndUpdate(
        id,
        { orderStatus },
        { new: true },
      );
      if (!updated) {
        throw new BadRequestException('Order not found');
      }
      return {
        message: `Order ${orderStatus.toLowerCase()} successfully`,
        success: true,
        result: updated,
      };
    } catch (error) {
      throw new BadRequestException(error.message);
    }
  }

  async deleteOrder(id: string) {
    try {
      const deleted = await this.orderDB.findByIdAndDelete(id);
      if (!deleted) {
        throw new BadRequestException('Order not found');
      }
      return {
        message: 'Order removed successfully',
        success: true,
        result: deleted,
      };
    } catch (error) {
      throw new BadRequestException(error.message);
    }
  }
}
