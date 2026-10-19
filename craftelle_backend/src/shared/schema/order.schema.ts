import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type OrderDocument = Order & Document;

export class WishListItemSchema {
  @Prop({ required: true })
  text: string;

  @Prop({ default: '' })
  specifications: string;

  @Prop({ default: null })
  quotedPrice: number | null;
}

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

  @Prop({ default: '' })
  sellerEmail: string;

  @Prop({ type: [OrderItemSchema], default: [] })
  items: OrderItemSchema[];

  @Prop({ type: [WishListItemSchema], default: [] })
  wishListItems: WishListItemSchema[];

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

  @Prop({ default: null })
  deliveryLatitude: number | null;

  @Prop({ default: null })
  deliveryLongitude: number | null;

  @Prop({ default: '' })
  customerPhone: string;

  @Prop({ default: 'Pending' })
  paymentStatus: string;

  @Prop({ default: '' })
  paymentReference: string;

  @Prop({ default: 'Pending' })
  orderStatus: string;

  @Prop({ default: false })
  requiresQuote: boolean;

  @Prop({ default: 'none' })
  quoteStatus: string;

  @Prop({ default: null })
  quotedExtrasTotal: number | null;

  @Prop({ default: null })
  quotedAt: Date | null;
}

export const OrderSchema = SchemaFactory.createForClass(Order);
