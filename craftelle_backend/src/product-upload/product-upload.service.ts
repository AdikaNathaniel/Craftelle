import { Injectable, HttpException, HttpStatus } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { ProductRepository } from '../shared/repositories/product.repository';
import { CreateProductDto } from './dto/create-product.dto';
import { Users } from '../shared/schema/users';

@Injectable()
export class ProductUploadService {
  constructor(
    private readonly productRepository: ProductRepository,
    @InjectModel(Users.name) private readonly userModel: Model<Users>,
  ) {}

  private async resolveSellerName(sellerEmail: string): Promise<string> {
    const user = await this.userModel.findOne({ email: sellerEmail }).exec();
    return user?.name || sellerEmail.split('@')[0];
  }

  async create(createProductDto: CreateProductDto) {
    try {
      // Resolve seller name from Users DB
      const resolvedName = await this.resolveSellerName(createProductDto.sellerEmail);
      createProductDto.sellerName = resolvedName;

      const product = await this.productRepository.create(createProductDto);
      return {
        success: true,
        message: 'Product created successfully',
        result: product,
      };
    } catch (error) {
      throw new HttpException(
        `Failed to create product: ${error.message}`,
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  async findAll() {
    try {
      const products = await this.productRepository.findAll();
      return {
        success: true,
        result: products,
      };
    } catch (error) {
      throw new HttpException(
        `Failed to fetch products: ${error.message}`,
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  async findOne(id: string) {
    try {
      const product = await this.productRepository.findById(id);
      if (!product) {
        throw new HttpException('Product not found', HttpStatus.NOT_FOUND);
      }
      return {
        success: true,
        result: product,
      };
    } catch (error) {
      throw new HttpException(
        error.message || 'Failed to fetch product',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  async findBySeller(sellerEmail: string) {
    try {
      const products = await this.productRepository.findBySeller(sellerEmail);
      return {
        success: true,
        result: products,
      };
    } catch (error) {
      throw new HttpException(
        `Failed to fetch seller products: ${error.message}`,
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  async update(id: string, updateData: Partial<CreateProductDto> & { sellerEmail?: string }) {
    try {
      const existing = await this.productRepository.findById(id);
      if (!existing) {
        throw new HttpException('Product not found', HttpStatus.NOT_FOUND);
      }

      if (!updateData.sellerEmail || updateData.sellerEmail !== existing.sellerEmail) {
        throw new HttpException(
          'Only the seller who created this product can update it',
          HttpStatus.FORBIDDEN,
        );
      }

      // Resolve seller name from Users DB
      const resolvedName = await this.resolveSellerName(updateData.sellerEmail);
      updateData.sellerName = resolvedName;

      const product = await this.productRepository.updateOne(id, updateData);
      return {
        success: true,
        message: 'Product updated successfully',
        result: product,
      };
    } catch (error) {
      throw new HttpException(
        error.message || 'Failed to update product',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  async refreshAllSellerNames() {
    try {
      // Find the actual seller account
      const seller = await this.userModel.findOne({ type: 'Seller' }).exec();
      if (!seller) {
        return { success: false, message: 'No seller account found' };
      }

      const products = await this.productRepository.findAll();
      let updated = 0;
      for (const product of products) {
        // Fix both sellerEmail and sellerName to match the actual seller
        if (product.sellerEmail !== seller.email || product.sellerName !== seller.name) {
          await this.productRepository.updateOne(product._id.toString(), {
            sellerEmail: seller.email,
            sellerName: seller.name,
          });
          updated++;
        }
      }
      return { success: true, message: `Updated ${updated} product(s) to seller: ${seller.name} (${seller.email})` };
    } catch (error) {
      throw new HttpException(
        `Failed to refresh seller names: ${error.message}`,
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  async delete(id: string, sellerEmail?: string) {
    try {
      const existing = await this.productRepository.findById(id);
      if (!existing) {
        throw new HttpException('Product not found', HttpStatus.NOT_FOUND);
      }

      if (!sellerEmail || sellerEmail !== existing.sellerEmail) {
        throw new HttpException(
          'Only the seller who created this product can delete it',
          HttpStatus.FORBIDDEN,
        );
      }

      const product = await this.productRepository.deleteOne(id);
      return {
        success: true,
        message: 'Product deleted successfully',
      };
    } catch (error) {
      throw new HttpException(
        error.message || 'Failed to delete product',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }
}
