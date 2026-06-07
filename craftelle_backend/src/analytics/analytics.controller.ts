import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { AnalyticsService } from './analytics.service';
import { Roles } from 'src/shared/middleware/role.decorators';
import { RolesGuard } from 'src/shared/middleware/roles.guard';
import { userTypes } from 'src/shared/schema/users';

@Controller('analytics')
@UseGuards(RolesGuard)
export class AnalyticsController {
  constructor(private readonly analyticsService: AnalyticsService) {}

  @Get('summary')
  @Roles(userTypes.ANALYST, userTypes.ADMIN)
  async getSummary(
    @Query('days') days?: string,
  ) {
    const daysNum = parseInt(days) || 30;
    return this.analyticsService.getSummary(daysNum);
  }

  @Get('top-products')
  @Roles(userTypes.ANALYST, userTypes.ADMIN)
  async getTopProducts(
    @Query('days') days?: string,
    @Query('limit') limit?: string,
  ) {
    const daysNum = parseInt(days) || 30;
    const limitNum = parseInt(limit) || 10;
    return this.analyticsService.getTopProducts(daysNum, limitNum);
  }

  @Get('peak-times')
  @Roles(userTypes.ANALYST, userTypes.ADMIN)
  async getPeakTimes(
    @Query('days') days?: string,
  ) {
    const daysNum = parseInt(days) || 30;
    return this.analyticsService.getPeakTimes(daysNum);
  }

  @Get('delivery-locations')
  @Roles(userTypes.ANALYST, userTypes.ADMIN)
  async getDeliveryLocations(
    @Query('days') days?: string,
    @Query('limit') limit?: string,
  ) {
    const daysNum = parseInt(days) || 30;
    const limitNum = parseInt(limit) || 10;
    return this.analyticsService.getDeliveryLocations(daysNum, limitNum);
  }

  @Get('repeated-customers')
  @Roles(userTypes.ANALYST, userTypes.ADMIN)
  async getRepeatedCustomers(
    @Query('days') days?: string,
    @Query('limit') limit?: string,
  ) {
    const daysNum = parseInt(days) || 30;
    const limitNum = parseInt(limit) || 20;
    return this.analyticsService.getRepeatedCustomers(daysNum, limitNum);
  }
}
