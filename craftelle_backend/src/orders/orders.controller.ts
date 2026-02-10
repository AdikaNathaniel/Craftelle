import { Body, Controller, Delete, Get, Param, Post, Query } from '@nestjs/common';
import { OrderService } from 'src/orders/orders.service';
import { CreateOrderDto } from './dto/create-order.dto';

@Controller('orders')
export class OrderController {
  constructor(private readonly orderService: OrderService) {}

  @Post()
  async createOrder(@Body() createOrderDto: CreateOrderDto) {
    return await this.orderService.createOrder(createOrderDto);
  }

  @Get()
  async getOrders(@Query('customerEmail') customerEmail?: string) {
    if (customerEmail) {
      return await this.orderService.getOrdersByCustomer(customerEmail);
    }
    return await this.orderService.getAllOrders();
  }

  @Delete(':id')
  async deleteOrder(@Param('id') id: string) {
    return await this.orderService.deleteOrder(id);
  }
}
