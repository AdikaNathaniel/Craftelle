import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ChatGateway } from './chat-gateway';
import { ChatController } from './chat.controller';
import { MessageService } from './message.service';
import { Message, MessageSchema } from '../shared/schema/message.schema';
import { Users, UserSchema } from '../shared/schema/users';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Message.name, schema: MessageSchema },
      { name: Users.name, schema: UserSchema },
    ])
  ],
  controllers: [ChatController],
  providers: [ChatGateway, MessageService],
  exports: [MessageService],
})
export class ChatRealTimeModule {}
