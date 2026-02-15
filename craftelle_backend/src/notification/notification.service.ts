// src/notification/notification.service.ts
import { Injectable, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Notification } from 'src/shared/schema/notification.schema';
import { CreateNotificationDto } from  'src/users/dto/create-notification.dto';
import { UpdateNotificationDto } from 'src/users/dto/update-notification.dto';
import { SmsNotificationService } from './sms-notification.service';
import * as admin from 'firebase-admin';

@Injectable()
export class NotificationService {
  private readonly logger = new Logger(NotificationService.name);

  constructor(
    @InjectModel(Notification.name)
    private notificationModel: Model<Notification>,
    private readonly smsService: SmsNotificationService,
  ) {}

  async create(createNotificationDto: CreateNotificationDto): Promise<Notification> {
    const createdNotification = new this.notificationModel(createNotificationDto);
    const savedNotification = await createdNotification.save();

    const now = new Date();
    const scheduledTime = new Date(createNotificationDto.scheduledAt);

    if (scheduledTime <= now) {
      this.logger.log('Sending immediate notification');
      await this.smsService.sendSms(savedNotification);
      await this.markAsSent(savedNotification._id.toString());
    } else {
      this.logger.log(`Scheduling notification for ${scheduledTime}`);
      await this.smsService.sendScheduledSms(savedNotification);
    }

    // Send FCM push notification to role-based topic
    this.sendPushNotification(
      savedNotification.role,
      savedNotification.message,
    ).catch(err => this.logger.error('FCM push failed:', err));

    return savedNotification;
  }

  async findAll(): Promise<Notification[]> {
    return this.notificationModel.find().exec();
  }

  async findOne(id: string): Promise<Notification> {
    return this.notificationModel.findById(id).exec();
  }

  async findByRole(role: string): Promise<Notification[]> {
    return this.notificationModel.find({ role }).exec();
  }

  async update(
    id: string,
    updateNotificationDto: UpdateNotificationDto,
  ): Promise<Notification> {
    return this.notificationModel
      .findByIdAndUpdate(id, updateNotificationDto, { new: true })
      .exec();
  }

  async remove(id: string): Promise<Notification> {
    return this.notificationModel.findByIdAndDelete(id).exec();
  }

  async markAsSent(id: string): Promise<Notification> {
    return this.notificationModel
      .findByIdAndUpdate(
        id,
        { isSent: true, sentAt: new Date() },
        { new: true },
      )
      .exec();
  }

  async markAsRead(id: string): Promise<Notification> {
    return this.notificationModel
      .findByIdAndUpdate(
        id,
        { isRead: true, readAt: new Date() },
        { new: true },
      )
      .exec();
  }

  async getPendingNotifications(): Promise<Notification[]> {
    const now = new Date();
    return this.notificationModel
      .find({ isSent: false, scheduledAt: { $lte: now } })
      .exec();
  }

  private async sendPushNotification(role: string, message: string) {
    if (!admin.apps.length) {
      this.logger.warn('Firebase Admin not initialized, skipping push notification');
      return;
    }

    const topic = `role_${role}`;
    await admin.messaging().send({
      topic,
      notification: {
        title: 'Craftelle',
        body: message,
      },
      android: {
        notification: {
          channelId: 'craftelle_notifications',
          priority: 'high' as const,
        },
      },
    });
    this.logger.log(`Push notification sent to topic: ${topic}`);
  }
}