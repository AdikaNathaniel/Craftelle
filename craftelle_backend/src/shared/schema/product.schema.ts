import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export class SizePrice {
  @Prop()
  small?: number;

  @Prop()
  medium?: number;

  @Prop()
  large?: number;

  @Prop()
  extraLarge?: number;
}

@Schema({
  timestamps: true,
})
export class Product extends Document {
  @Prop({ required: true })
  name: string;

  @Prop({ required: true })
  description: string;

  @Prop({ required: true })
  imageUrl: string;

  @Prop({ default: false })
  hasSizes: boolean;

  @Prop({ type: SizePrice })
  sizePrices?: SizePrice;

  @Prop()
  basePrice?: number;

  @Prop({ required: true })
  sellerEmail: string;

  @Prop({ required: true })
  sellerName: string;

  @Prop({ default: true })
  isActive: boolean;
}

export const ProductSchema = SchemaFactory.createForClass(Product);
