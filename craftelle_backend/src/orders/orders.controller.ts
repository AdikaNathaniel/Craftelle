import { Body, Controller, Delete, Get, Param, Patch, Post, Query } from '@nestjs/common';
import { OrderService } from 'src/orders/orders.service';
import { CreateOrderDto, UpdateOrderStatusDto, SubmitQuoteDto, PayQuoteDto } from './dto/create-order.dto';

@Controller('orders')
export class OrderController {
  constructor(private readonly orderService: OrderService) {}

  @Post()
  async createOrder(@Body() createOrderDto: CreateOrderDto) {
    return await this.orderService.createOrder(createOrderDto);
  }

  @Get()
  async getOrders(
    @Query('customerEmail') customerEmail?: string,
    @Query('sellerEmail') sellerEmail?: string,
  ) {
    if (customerEmail) {
      return await this.orderService.getOrdersByCustomer(customerEmail);
    }
    if (sellerEmail) {
      return await this.orderService.getOrdersBySeller(sellerEmail);
    }
    return await this.orderService.getAllOrders();
  }

  @Patch(':id/status')
  async updateOrderStatus(
    @Param('id') id: string,
    @Body() updateOrderStatusDto: UpdateOrderStatusDto,
  ) {
    return await this.orderService.updateOrderStatus(
      id,
      updateOrderStatusDto.orderStatus,
    );
  }

  @Patch(':id/quote')
  async submitQuote(
    @Param('id') id: string,
    @Body() submitQuoteDto: SubmitQuoteDto,
  ) {
    return await this.orderService.submitQuote(id, submitQuoteDto);
  }

  @Patch(':id/pay-quote')
  async payQuote(
    @Param('id') id: string,
    @Body() payQuoteDto: PayQuoteDto,
  ) {
    return await this.orderService.payQuote(id, payQuoteDto);
  }

  @Delete(':id')
  async deleteOrder(@Param('id') id: string) {
    return await this.orderService.deleteOrder(id);
  }
}
