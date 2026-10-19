import { BadRequestException, Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Rating, RatingDocument } from 'src/shared/schema/rating.schema';
import { CreateRatingDto } from './dto/create-rating.dto';

@Injectable()
export class RatingService {
  constructor(
    @InjectModel(Rating.name) private ratingDB: Model<RatingDocument>,
  ) {}

  async createOrUpdateRating(dto: CreateRatingDto) {
    try {
      if (dto.type === 'product' && !dto.productId) {
        throw new BadRequestException(
          'Product ratings must include productId',
        );
      }

      const filter: any = {
        userEmail: dto.userEmail,
        type: dto.type,
      };
      if (dto.type === 'product') {
        filter.productId = dto.productId;
      }

      const rating = await this.ratingDB.findOneAndUpdate(
        filter,
        {
          stars: dto.stars,
          reviewText: dto.reviewText || '',
          productName: dto.productName || '',
          sellerEmail: dto.sellerEmail || '',
          type: dto.type,
          userEmail: dto.userEmail,
          productId: dto.productId || '',
        },
        { new: true, upsert: true },
      );

      return {
        message: 'Rating saved successfully',
        success: true,
        result: rating,
      };
    } catch (error) {
      throw new BadRequestException(error.message);
    }
  }

  async getProductAverageRating(productId: string) {
    try {
      const result = await this.ratingDB.aggregate([
        { $match: { type: 'product', productId } },
        {
          $group: {
            _id: null,
            averageRating: { $avg: '$stars' },
            totalRatings: { $sum: 1 },
          },
        },
      ]);

      return {
        message: 'Product rating retrieved successfully',
        success: true,
        result:
          result.length > 0
            ? {
                averageRating:
                  Math.round(result[0].averageRating * 10) / 10,
                totalRatings: result[0].totalRatings,
              }
            : { averageRating: 0, totalRatings: 0 },
      };
    } catch (error) {
      throw new BadRequestException(error.message);
    }
  }

  async getProductRatings(productId: string) {
    try {
      const ratings = await this.ratingDB
        .find({ type: 'product', productId })
        .sort({ createdAt: -1 });
      return {
        message: 'Product ratings retrieved successfully',
        success: true,
        result: ratings,
      };
    } catch (error) {
      throw new BadRequestException(error.message);
    }
  }

  async getUserProductRating(userEmail: string, productId: string) {
    try {
      const rating = await this.ratingDB.findOne({
        userEmail,
        type: 'product',
        productId,
      });
      return {
        message: rating ? 'User rating found' : 'No rating found',
        success: true,
        result: rating,
      };
    } catch (error) {
      throw new BadRequestException(error.message);
    }
  }

  async getServiceAverageRating() {
    try {
      const result = await this.ratingDB.aggregate([
        { $match: { type: 'service' } },
        {
          $group: {
            _id: null,
            averageRating: { $avg: '$stars' },
            totalRatings: { $sum: 1 },
          },
        },
      ]);

      return {
        message: 'Service rating retrieved successfully',
        success: true,
        result:
          result.length > 0
            ? {
                averageRating:
                  Math.round(result[0].averageRating * 10) / 10,
                totalRatings: result[0].totalRatings,
              }
            : { averageRating: 0, totalRatings: 0 },
      };
    } catch (error) {
      throw new BadRequestException(error.message);
    }
  }

  async getAllServiceRatings() {
    try {
      const ratings = await this.ratingDB
        .find({ type: 'service' })
        .sort({ createdAt: -1 });
      return {
        message: 'All service ratings retrieved successfully',
        success: true,
        result: ratings,
      };
    } catch (error) {
      throw new BadRequestException(error.message);
    }
  }

  async getUserServiceRating(userEmail: string) {
    try {
      const rating = await this.ratingDB.findOne({
        userEmail,
        type: 'service',
      });
      return {
        message: rating ? 'User service rating found' : 'No rating found',
        success: true,
        result: rating,
      };
    } catch (error) {
      throw new BadRequestException(error.message);
    }
  }

  async deleteRating(id: string) {
    try {
      const deleted = await this.ratingDB.findByIdAndDelete(id);
      if (!deleted) {
        throw new BadRequestException('Rating not found');
      }
      return {
        message: 'Rating deleted successfully',
        success: true,
        result: deleted,
      };
    } catch (error) {
      throw new BadRequestException(error.message);
    }
  }
}
