import { Controller, Get, Param } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { MessageService } from './message.service';
import { Users } from 'src/shared/schema/users';

@Controller('chat')
export class ChatController {
  constructor(
    private readonly messageService: MessageService,
    @InjectModel(Users.name) private userDB: Model<Users>,
  ) {}

  @Get('users')
  async getChatUsers() {
    try {
      const users = await this.userDB
        .find({ isActive: true })
        .select('name email type username')
        .lean();

      return {
        success: true,
        message: 'Users retrieved successfully',
        data: users.map((u: any) => ({
          id: u._id.toString(),
          name: u.name,
          email: u.email,
          type: u.type,
          username: u.username,
        })),
      };
    } catch (error) {
      return {
        success: false,
        message: error.message || 'Failed to fetch users',
        data: [],
      };
    }
  }

  @Get('conversations/:userId')
  async getUserConversations(@Param('userId') userId: string) {
    try {
      const conversations = await this.messageService.getUserConversations(userId);

      // Enrich with user info
      const enriched = await Promise.all(
        conversations.map(async (conv: any) => {
          const lastMsg = conv.lastMessage;
          const otherUserId = lastMsg.senderId === userId
            ? lastMsg.receiverId
            : lastMsg.senderId;

          // Try to find user by ID first, then by email
          let otherUser = await this.userDB
            .findById(otherUserId)
            .select('name email type')
            .lean();

          if (!otherUser) {
            otherUser = await this.userDB
              .findOne({ email: otherUserId })
              .select('name email type')
              .lean();
          }

          return {
            roomId: conv._id,
            lastMessage: lastMsg.content,
            lastMessageTime: lastMsg.timestamp,
            unreadCount: conv.unreadCount,
            otherUser: otherUser
              ? {
                  id: otherUser._id.toString(),
                  name: (otherUser as any).name,
                  email: (otherUser as any).email,
                  type: (otherUser as any).type,
                }
              : {
                  id: otherUserId,
                  name: lastMsg.senderName || otherUserId,
                  email: otherUserId,
                  type: lastMsg.senderRole || 'Unknown',
                },
          };
        }),
      );

      return {
        success: true,
        message: 'Conversations retrieved successfully',
        data: enriched,
      };
    } catch (error) {
      return {
        success: false,
        message: error.message || 'Failed to fetch conversations',
        data: [],
      };
    }
  }

  @Get('unread/:userId')
  async getUnreadCount(@Param('userId') userId: string) {
    try {
      const count = await this.messageService.getUnreadMessagesCount(userId);
      return {
        success: true,
        data: { unreadCount: count },
      };
    } catch (error) {
      return {
        success: false,
        message: error.message || 'Failed to fetch unread count',
        data: { unreadCount: 0 },
      };
    }
  }
}
