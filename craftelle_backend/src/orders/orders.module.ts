import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { Order, OrderSchema } from 'src/shared/schema/order.schema';
import { OrderController } from 'src/orders/orders.controller';
import { OrderService } from 'src/orders/orders.service';
import { PaystackModule } from 'src/paystack/paystack.module';
import { EmailModule } from 'src/email/email.module';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: Order.name, schema: OrderSchema }]),
    PaystackModule,
    EmailModule,
  ],
  controllers: [OrderController],
  providers: [OrderService],
})
export class OrderModule {}
