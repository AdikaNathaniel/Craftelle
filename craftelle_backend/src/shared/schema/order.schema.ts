import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type OrderDocument = Order & Document;

@Schema({ timestamps: true })
export class Order {
  @Prop({ required: true })
  productName: string;

  @Prop({ required: true })
  quantity: number;

  @Prop({ default: 'Pending' })
  status: string;

  @Prop({ default: '' })
  userId: string;

  @Prop({ default: '' })
  userEmail: string;

  @Prop({ default: 0 })
  price: number;

  @Prop({ default: 0 })
  totalAmount: number;

  @Prop({ default: 'General' })
  category: string;

  @Prop({ default: '' })
  deliveryCity: string;

  @Prop({ default: '' })
  deliveryRegion: string;
}

export const OrderSchema = SchemaFactory.createForClass(Order);