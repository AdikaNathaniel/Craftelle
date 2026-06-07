import { BadRequestException, Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Order, OrderDocument } from 'src/shared/schema/order.schema';
import { Users, userTypes } from 'src/shared/schema/users';
import { CreateOrderDto, SubmitQuoteDto, PayQuoteDto } from './dto/create-order.dto';
import { PaystackService } from 'src/paystack/paystack.service';
import { EmailService } from 'src/email/email.service';
import { NotificationService } from 'src/notification/notification.service';

@Injectable()
export class OrderService {
  constructor(
    @InjectModel(Order.name) private orderDB: Model<OrderDocument>,
    @InjectModel(Users.name) private userDB: Model<Users>,
    private readonly paystackService: PaystackService,
    private readonly emailService: EmailService,
    private readonly notificationService: NotificationService,
  ) {}

  /**
   * Always resolves the current seller email from the Users DB.
   * Never relies on hardcoded or cached emails from products/orders.
   */
  private async resolveSellerEmail(): Promise<string> {
    const seller = await this.userDB.findOne({ type: userTypes.SELLER }).exec();
    return seller?.email || '';
  }

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

      // Always resolve seller from Users DB — never trust product/item emails
      const sellerEmail = await this.resolveSellerEmail();

      const newOrder = new this.orderDB({
        customerEmail: createOrderDto.customerEmail,
        sellerEmail,
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
      } else if (sellerEmail) {
        // Notify seller about new order that needs pricing
        this.emailService.sendNewQuoteOrderToSeller(newOrder.toObject(), sellerEmail).catch((err) => {
          console.error('Failed to send new quote order email to seller:', err);
        });
        this.notificationService.sendPushToUser(
          sellerEmail,
          'New Order',
          `A new order needs pricing. Review extras in the app.`,
        ).catch((err) => {
          console.error('Failed to send push to seller:', err);
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
      if (order.quoteStatus !== 'pending' && order.quoteStatus !== 'quoted') {
        throw new BadRequestException(`Cannot quote an order with status: ${order.quoteStatus}`);
      }

      const isUpdate = order.quoteStatus === 'quoted';

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

      // Refresh seller email on the order to current value
      const currentSellerEmail = await this.resolveSellerEmail();
      order.sellerEmail = currentSellerEmail;
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
        isUpdate ? 'Quote Updated' : 'Quote Ready',
        isUpdate
          ? `Your quote has been updated to GHS ${grandTotal.toLocaleString()}. Pay now in the app.`
          : `Your quote is GHS ${grandTotal.toLocaleString()}. Pay now in the app.`,
      ).catch((err) => {
        console.error('Failed to send quote push notification:', err);
      });

      return {
        message: isUpdate ? 'Quote updated successfully' : 'Quote submitted successfully',
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

      // Resolve current seller email fresh from DB
      const currentSellerEmail = await this.resolveSellerEmail();
      order.sellerEmail = currentSellerEmail;
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
      // Verify this user is actually a seller
      const seller = await this.userDB.findOne({
        email: sellerEmail,
        type: userTypes.SELLER,
      }).exec();

      if (!seller) {
        throw new BadRequestException('Seller account not found');
      }

      // Return all orders — the seller sees everything regardless of
      // what email was stored on old orders or product data
      const orders = await this.orderDB
        .find()
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
