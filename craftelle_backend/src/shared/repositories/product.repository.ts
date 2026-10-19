import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Product } from '../schema/product.schema';

@Injectable()
export class ProductRepository {
  constructor(
    @InjectModel(Product.name) private readonly productModel: Model<Product>,
  ) {}

  async findAll() {
    return await this.productModel.find({ isActive: true });
  }

  async findOne(query: any) {
    return await this.productModel.findOne(query);
  }

  async findById(id: string) {
    return await this.productModel.findById(id);
  }

  async create(data: Record<string, any>) {
    return await this.productModel.create(data);
  }

  async updateOne(id: string, data: Record<string, any>) {
    return await this.productModel.findByIdAndUpdate(id, data, { new: true });
  }

  async deleteOne(id: string) {
    return await this.productModel.findByIdAndDelete(id);
  }

  async findBySeller(sellerEmail: string) {
    return await this.productModel.find({ sellerEmail, isActive: true });
  }
}
