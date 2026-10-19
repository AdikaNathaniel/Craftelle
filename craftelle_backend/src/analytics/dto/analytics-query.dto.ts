import { IsNumber, IsOptional } from 'class-validator';
import { Transform } from 'class-transformer';

export class AnalyticsQueryDto {
  @IsOptional()
  @IsNumber()
  @Transform(({ value }) => parseInt(value) || 30)
  days?: number = 30;

  @IsOptional()
  @IsNumber()
  @Transform(({ value }) => parseInt(value) || 10)
  limit?: number = 10;
}
