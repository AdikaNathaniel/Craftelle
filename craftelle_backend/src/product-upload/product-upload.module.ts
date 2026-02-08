import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ProductUploadController } from './product-upload.controller';
import { ProductUploadService } from './product-upload.service';
import { Product, ProductSchema } from '../shared/schema/product.schema';
import { ProductRepository } from '../shared/repositories/product.repository';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: Product.name, schema: ProductSchema }]),
  ],
  controllers: [ProductUploadController],
  providers: [ProductUploadService, ProductRepository],
  exports: [ProductUploadService, ProductRepository],
})
export class ProductUploadModule {}
