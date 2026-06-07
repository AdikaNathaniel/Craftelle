import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { HttpModule } from '@nestjs/axios';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { ScheduleModule } from '@nestjs/schedule';
import { TerminusModule } from '@nestjs/terminus';
import { MulterModule } from '@nestjs/platform-express';
import * as Joi from 'joi';

// Controllers
import { AppController } from './app.controller';

// Services
import { AppService } from './app.service';

// Craftelle Feature Modules
import { UsersModule } from './users/users.module';
import { AuthModule } from './auth/auth.module';
import { OrderModule } from './orders/orders.module';
import { PaymentsModule } from './payments/payments.module';
import { StripeModule } from './payments/stripe.module';
import { PaystackModule } from './paystack/paystack.module';
import { ProductUploadModule } from './product-upload/product-upload.module';
import { EmailModule } from 'src/email/email.module';
import { NotificationModule } from 'src/notification/notification.module';
import { ChatbotModule } from './chat/chat.module';
import { ChatRealTimeModule } from './chat-real-time/chat-real-time.module';
import { SearchModule } from './search/search.module';
import { TrackingModule } from 'src/tracking/tracking.module';
import { AnalyticsModule } from './analytics/analytics.module';
import { SupportModule } from './support/support.module';
import { PinModule } from './pin/pin.module';
import { RatingModule } from './rating/rating.module';
import { ReportModule } from './report/report.module';
import { HttpModules } from 'src/shared/http/http.module';

@Module({
  imports: [
    // Configuration
    ConfigModule.forRoot({
      isGlobal: true,
      validationSchema: Joi.object({
        MONGODB_URI: Joi.string().required(),
        FRONTEND_URL: Joi.string().required(),
      }),
    }),

    // Database
    MongooseModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: async (configService: ConfigService) => ({
        uri: configService.get<string>('MONGODB_URI'),
        w: 1,
        retryWrites: true,
        maxPoolSize: 10,
      }),
      inject: [ConfigService],
    }),

    // HTTP Client
    HttpModule.registerAsync({
      imports: [ConfigModule],
      useFactory: async (configService: ConfigService) => ({
        timeout: configService.get('HTTP_TIMEOUT') || 5000,
        maxRedirects: configService.get('HTTP_MAX_REDIRECTS') || 5,
      }),
      inject: [ConfigService],
    }),

    // Scheduled Tasks
    ScheduleModule.forRoot(),

    // File Upload
    MulterModule.register({ dest: './uploads' }),

    // Health Check
    TerminusModule,

    // Craftelle Feature Modules
    UsersModule,
    AuthModule,
    OrderModule,
    PaymentsModule,
    StripeModule,
    PaystackModule,
    ProductUploadModule,
    EmailModule,
    NotificationModule,
    ChatbotModule,
    ChatRealTimeModule,
    SearchModule,
    TrackingModule,
    AnalyticsModule,
    SupportModule,
    PinModule,
    RatingModule,
    ReportModule,
    HttpModules,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
