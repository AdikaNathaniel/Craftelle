import {
  IsNotEmpty,
  IsString,
  IsBoolean,
  IsOptional,
  IsNumber,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';

export class SizePriceDto {
  @IsOptional()
  @IsNumber()
  small?: number;

  @IsOptional()
  @IsNumber()
  medium?: number;

  @IsOptional()
  @IsNumber()
  large?: number;

  @IsOptional()
  @IsNumber()
  extraLarge?: number;
}

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
  @ValidateNested()
  @Type(() => SizePriceDto)
  sizePrices?: SizePriceDto;

  @IsOptional()
  @IsNumber()
  basePrice?: number;

  @IsNotEmpty()
  @IsString()
  sellerEmail: string;

  @IsNotEmpty()
  @IsString()
  sellerName: string;
}
