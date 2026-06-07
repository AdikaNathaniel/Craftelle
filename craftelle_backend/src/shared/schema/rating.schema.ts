import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type RatingDocument = Rating & Document;

@Schema({ timestamps: true })
export class Rating extends Document {
  @Prop({ required: true, enum: ['product', 'service'] })
  type: string;

  @Prop({ required: true })
  userEmail: string;

  @Prop({ required: true, min: 1, max: 5 })
  stars: number;

  @Prop({ default: '' })
  reviewText: string;

  @Prop()
  productId: string;

  @Prop({ default: '' })
  productName: string;

  @Prop({ default: '' })
  sellerEmail: string;
}

export const RatingSchema = SchemaFactory.createForClass(Rating);

RatingSchema.index(
  { userEmail: 1, type: 1, productId: 1 },
  { unique: true, sparse: true },
);
