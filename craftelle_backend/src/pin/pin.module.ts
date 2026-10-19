import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { PinController } from './pin.controller';
import { PinService } from './pin.service';
import { Pin, PinSchema } from 'src/shared/schema/pin.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Pin.name, schema: PinSchema },
    ]),
  ],
  controllers: [PinController],
  providers: [PinService],
  exports: [PinService],
})
export class PinModule {}
