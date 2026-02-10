import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type OrderDocument = Order & Document;

export class OrderItemSchema {
  @Prop({ required: true })
  productName: string;

  @Prop({ default: '' })
  imageUrl: string;

  @Prop()
  selectedSize?: string;

  @Prop({ required: true })
  price: number;

  @Prop({ default: 1 })
  quantity: number;

  @Prop({ default: '' })
  sellerName: string;

  @Prop({ default: '' })
  sellerEmail: string;
}

@Schema({ timestamps: true })
export class Order {
  @Prop({ required: true })
  customerEmail: string;

  @Prop({ type: [OrderItemSchema], default: [] })
  items: OrderItemSchema[];

  @Prop({ type: [String], default: [] })
  wishListItems: string[];

  @Prop({ default: 0 })
  totalPrice: number;

  @Prop({ default: 'Pending' })
  status: string;

  @Prop({ default: '' })
  deliveryCity: string;

  @Prop({ default: '' })
  deliveryRegion: string;

  @Prop({ default: '' })
  deliveryAddress: string;

  @Prop({ default: '' })
  customerPhone: string;

  @Prop({ default: 'Pending' })
  paymentStatus: string;

  @Prop({ default: 'Pending' })
  orderStatus: string;
}

export const OrderSchema = SchemaFactory.createForClass(Order);
