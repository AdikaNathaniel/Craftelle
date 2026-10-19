import {
  IsNotEmpty,
  IsString,
  IsNumber,
  IsOptional,
  Min,
  Max,
  IsIn,
} from 'class-validator';

export class CreateRatingDto {
  @IsNotEmpty()
  @IsString()
  @IsIn(['product', 'service'])
  type: string;

  @IsNotEmpty()
  @IsString()
  userEmail: string;

  @IsNotEmpty()
  @IsNumber()
  @Min(1)
  @Max(5)
  stars: number;

  @IsOptional()
  @IsString()
  reviewText?: string;

  @IsOptional()
  @IsString()
  productId?: string;

  @IsOptional()
  @IsString()
  productName?: string;

  @IsOptional()
  @IsString()
  sellerEmail?: string;
}

export class UpdateRatingDto {
  @IsOptional()
  @IsNumber()
  @Min(1)
  @Max(5)
  stars?: number;

  @IsOptional()
  @IsString()
  reviewText?: string;
}
