import { Injectable, HttpException, HttpStatus } from '@nestjs/common';
import { ProductRepository } from '../shared/repositories/product.repository';
import { CreateProductDto } from './dto/create-product.dto';

@Injectable()
export class ProductUploadService {
  constructor(private readonly productRepository: ProductRepository) {}

  async create(createProductDto: CreateProductDto) {
    try {
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

  async update(id: string, updateData: Partial<CreateProductDto>) {
    try {
      const product = await this.productRepository.updateOne(id, updateData);
      if (!product) {
        throw new HttpException('Product not found', HttpStatus.NOT_FOUND);
      }
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

  async delete(id: string) {
    try {
      const product = await this.productRepository.deleteOne(id);
      if (!product) {
        throw new HttpException('Product not found', HttpStatus.NOT_FOUND);
      }
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
