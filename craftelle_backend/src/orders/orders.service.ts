import { BadRequestException, Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Order, OrderDocument } from 'src/shared/schema/order.schema';
import { CreateOrderDto } from './dto/create-order.dto';

@Injectable()
export class OrderService {
  constructor(
    @InjectModel(Order.name) private orderDB: Model<OrderDocument>,
  ) {}

  async createOrder(createOrderDto: CreateOrderDto) {
    try {
      const newOrder = new this.orderDB({
        customerEmail: createOrderDto.customerEmail,
        items: createOrderDto.items || [],
        wishListItems: createOrderDto.wishListItems || [],
        totalPrice: createOrderDto.totalPrice || 0,
        status: 'Pending',
        deliveryCity: createOrderDto.deliveryCity || '',
        deliveryRegion: createOrderDto.deliveryRegion || '',
        deliveryAddress: createOrderDto.deliveryAddress || '',
        customerPhone: createOrderDto.customerPhone || '',
        paymentStatus: createOrderDto.paymentStatus || 'Pending',
      });

      await newOrder.save();

      return {
        message: 'Order placed successfully',
        success: true,
        result: newOrder,
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
