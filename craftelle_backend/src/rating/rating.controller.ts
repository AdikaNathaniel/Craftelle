import { Body, Controller, Delete, Get, Param, Post } from '@nestjs/common';
import { RatingService } from './rating.service';
import { CreateRatingDto } from './dto/create-rating.dto';

@Controller('ratings')
export class RatingController {
  constructor(private readonly ratingService: RatingService) {}

  @Post()
  async createOrUpdateRating(@Body() dto: CreateRatingDto) {
    return await this.ratingService.createOrUpdateRating(dto);
  }

  @Get('product/:productId/average')
  async getProductAverageRating(@Param('productId') productId: string) {
    return await this.ratingService.getProductAverageRating(productId);
  }

  @Get('product/:productId')
  async getProductRatings(@Param('productId') productId: string) {
    return await this.ratingService.getProductRatings(productId);
  }

  @Get('product/:productId/user/:userEmail')
  async getUserProductRating(
    @Param('productId') productId: string,
    @Param('userEmail') userEmail: string,
  ) {
    return await this.ratingService.getUserProductRating(userEmail, productId);
  }

  @Get('service/all')
  async getAllServiceRatings() {
    return await this.ratingService.getAllServiceRatings();
  }

  @Get('service/average')
  async getServiceAverageRating() {
    return await this.ratingService.getServiceAverageRating();
  }

  @Get('service/user/:userEmail')
  async getUserServiceRating(@Param('userEmail') userEmail: string) {
    return await this.ratingService.getUserServiceRating(userEmail);
  }

  @Delete(':id')
  async deleteRating(@Param('id') id: string) {
    return await this.ratingService.deleteRating(id);
  }
}
