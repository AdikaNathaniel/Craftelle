import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Delete,
  Put,
  HttpException,
  HttpStatus,
  Query,
} from '@nestjs/common';
import { ProductUploadService } from './product-upload.service';
import { CreateProductDto } from './dto/create-product.dto';

@Controller('products')
export class ProductUploadController {
  constructor(private readonly productUploadService: ProductUploadService) {}

  @Post()
  async create(@Body() createProductDto: CreateProductDto) {
    try {
      return await this.productUploadService.create(createProductDto);
    } catch (error) {
      throw new HttpException(
        {
          success: false,
          message: error.message,
        },
        HttpStatus.BAD_REQUEST,
      );
    }
  }

  @Get()
  async findAll(@Query('sellerEmail') sellerEmail?: string) {
    try {
      if (sellerEmail) {
        return await this.productUploadService.findBySeller(sellerEmail);
      }
      return await this.productUploadService.findAll();
    } catch (error) {
      throw new HttpException(
        {
          success: false,
          message: error.message,
        },
        HttpStatus.BAD_REQUEST,
      );
    }
  }

  @Get(':id')
  async findOne(@Param('id') id: string) {
    try {
      return await this.productUploadService.findOne(id);
    } catch (error) {
      throw new HttpException(
        {
          success: false,
          message: error.message,
        },
        HttpStatus.BAD_REQUEST,
      );
    }
  }

  @Put(':id')
  async update(
    @Param('id') id: string,
    @Body() updateData: Partial<CreateProductDto>,
  ) {
    try {
      return await this.productUploadService.update(id, updateData);
    } catch (error) {
      throw new HttpException(
        {
          success: false,
          message: error.message,
        },
        HttpStatus.BAD_REQUEST,
      );
    }
  }

  @Delete(':id')
  async delete(@Param('id') id: string) {
    try {
      return await this.productUploadService.delete(id);
    } catch (error) {
      throw new HttpException(
        {
          success: false,
          message: error.message,
        },
        HttpStatus.BAD_REQUEST,
      );
    }
  }
}
