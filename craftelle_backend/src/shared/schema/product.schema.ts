import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

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

  @Prop({ type: Map, of: Number })
  sizePrices?: Map<string, number>;

  @Prop()
  basePrice?: number;

  @Prop()
  priceDisplay?: string;

  @Prop({ required: true })
  sellerEmail: string;

  @Prop({ required: true })
  sellerName: string;

  @Prop({ default: true })
  isActive: boolean;
}

export const ProductSchema = SchemaFactory.createForClass(Product);
