import {
  IsNotEmpty,
  IsString,
  IsBoolean,
  IsOptional,
  IsNumber,
  IsObject,
} from 'class-validator';

export class CreateProductDto {
  @IsNotEmpty()
  @IsString()
  name: string;

  @IsNotEmpty()
  @IsString()
  description: string;

  @IsNotEmpty()
  @IsString()
  imageUrl: string;

  @IsBoolean()
  hasSizes: boolean;

  @IsOptional()
  @IsObject()
  sizePrices?: Record<string, number>;

  @IsOptional()
  @IsNumber()
  basePrice?: number;

  @IsOptional()
  @IsString()
  priceDisplay?: string;

  @IsNotEmpty()
  @IsString()
  sellerEmail: string;

  @IsNotEmpty()
  @IsString()
  sellerName: string;
}
