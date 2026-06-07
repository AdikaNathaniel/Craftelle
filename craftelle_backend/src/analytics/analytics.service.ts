import { Injectable, BadRequestException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Order, OrderDocument } from 'src/shared/schema/order.schema';
import { Users } from 'src/shared/schema/users';

@Injectable()
export class AnalyticsService {
  constructor(
    @InjectModel(Order.name) private orderDB: Model<OrderDocument>,
    @InjectModel(Users.name) private userDB: Model<Users>,
  ) {}

  private getDateFilter(days: number) {
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);
    return { createdAt: { $gte: startDate } };
  }

  async getSummary(days: number) {
    try {
      const dateFilter = this.getDateFilter(days);

      const result = await this.orderDB.aggregate([
        { $match: dateFilter },
        {
          $group: {
            _id: null,
            totalOrders: { $sum: 1 },
            totalRevenue: { $sum: '$totalAmount' },
            totalQuantity: { $sum: '$quantity' },
            uniqueCustomers: { $addToSet: '$userId' },
            avgOrderValue: { $avg: '$totalAmount' },
          },
        },
        {
          $project: {
            _id: 0,
            totalOrders: 1,
            totalRevenue: { $round: ['$totalRevenue', 2] },
            totalQuantity: 1,
            uniqueCustomers: { $size: '$uniqueCustomers' },
            avgOrderValue: { $round: ['$avgOrderValue', 2] },
          },
        },
      ]);

      const summary = result[0] || {
        totalOrders: 0,
        totalRevenue: 0,
        totalQuantity: 0,
        uniqueCustomers: 0,
        avgOrderValue: 0,
      };

      return {
        success: true,
        message: 'Analytics summary retrieved successfully',
        data: summary,
      };
    } catch (error) {
      throw new BadRequestException(error.message);
    }
  }

  async getTopProducts(days: number, limit: number) {
    try {
      const dateFilter = this.getDateFilter(days);

      const topProducts = await this.orderDB.aggregate([
        { $match: dateFilter },
        {
          $group: {
            _id: '$productName',
            totalOrdered: { $sum: '$quantity' },
            totalRevenue: { $sum: '$totalAmount' },
            orderCount: { $sum: 1 },
            category: { $first: '$category' },
          },
        },
        { $sort: { totalOrdered: -1 } },
        { $limit: limit },
        {
          $project: {
            _id: 0,
            productName: '$_id',
            totalOrdered: 1,
            totalRevenue: { $round: ['$totalRevenue', 2] },
            orderCount: 1,
            category: 1,
          },
        },
      ]);

      const categoryBreakdown = await this.orderDB.aggregate([
        { $match: dateFilter },
        {
          $group: {
            _id: '$category',
            totalOrdered: { $sum: '$quantity' },
            totalRevenue: { $sum: '$totalAmount' },
            orderCount: { $sum: 1 },
          },
        },
        { $sort: { totalOrdered: -1 } },
        {
          $project: {
            _id: 0,
            category: '$_id',
            totalOrdered: 1,
            totalRevenue: { $round: ['$totalRevenue', 2] },
            orderCount: 1,
          },
        },
      ]);

      return {
        success: true,
        message: 'Top products retrieved successfully',
        data: { topProducts, categoryBreakdown },
      };
    } catch (error) {
      throw new BadRequestException(error.message);
    }
  }

  async getPeakTimes(days: number) {
    try {
      const dateFilter = this.getDateFilter(days);

      const byHour = await this.orderDB.aggregate([
        { $match: dateFilter },
        {
          $group: {
            _id: { $hour: '$createdAt' },
            orderCount: { $sum: 1 },
            totalRevenue: { $sum: '$totalAmount' },
          },
        },
        { $sort: { _id: 1 } },
        {
          $project: {
            _id: 0,
            hour: '$_id',
            orderCount: 1,
            totalRevenue: { $round: ['$totalRevenue', 2] },
          },
        },
      ]);

      const byDayOfWeek = await this.orderDB.aggregate([
        { $match: dateFilter },
        {
          $group: {
            _id: { $dayOfWeek: '$createdAt' },
            orderCount: { $sum: 1 },
            totalRevenue: { $sum: '$totalAmount' },
          },
        },
        { $sort: { _id: 1 } },
        {
          $project: {
            _id: 0,
            dayOfWeek: '$_id',
            orderCount: 1,
            totalRevenue: { $round: ['$totalRevenue', 2] },
          },
        },
      ]);

      const dayNames = ['', 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
      const byDayNamed = byDayOfWeek.map((d) => ({
        ...d,
        dayName: dayNames[d.dayOfWeek] || 'Unknown',
      }));

      return {
        success: true,
        message: 'Peak times retrieved successfully',
        data: { byHour, byDayOfWeek: byDayNamed },
      };
    } catch (error) {
      throw new BadRequestException(error.message);
    }
  }

  async getDeliveryLocations(days: number, limit: number) {
    try {
      const dateFilter = this.getDateFilter(days);

      const byCity = await this.orderDB.aggregate([
        { $match: { ...dateFilter, deliveryCity: { $ne: '' } } },
        {
          $group: {
            _id: '$deliveryCity',
            orderCount: { $sum: 1 },
            totalRevenue: { $sum: '$totalAmount' },
            totalQuantity: { $sum: '$quantity' },
          },
        },
        { $sort: { orderCount: -1 } },
        { $limit: limit },
        {
          $project: {
            _id: 0,
            city: '$_id',
            orderCount: 1,
            totalRevenue: { $round: ['$totalRevenue', 2] },
            totalQuantity: 1,
          },
        },
      ]);

      const byRegion = await this.orderDB.aggregate([
        { $match: { ...dateFilter, deliveryRegion: { $ne: '' } } },
        {
          $group: {
            _id: '$deliveryRegion',
            orderCount: { $sum: 1 },
            totalRevenue: { $sum: '$totalAmount' },
            totalQuantity: { $sum: '$quantity' },
          },
        },
        { $sort: { orderCount: -1 } },
        { $limit: limit },
        {
          $project: {
            _id: 0,
            region: '$_id',
            orderCount: 1,
            totalRevenue: { $round: ['$totalRevenue', 2] },
            totalQuantity: 1,
          },
        },
      ]);

      // Total count for percentage calculation
      const totalOrders = await this.orderDB.countDocuments(dateFilter);

      return {
        success: true,
        message: 'Delivery locations retrieved successfully',
        data: { byCity, byRegion, totalOrders },
      };
    } catch (error) {
      throw new BadRequestException(error.message);
    }
  }

  async getRepeatedCustomers(days: number, limit: number) {
    try {
      const dateFilter = this.getDateFilter(days);

      const repeatedCustomers = await this.orderDB.aggregate([
        { $match: { ...dateFilter, userId: { $ne: '' } } },
        {
          $group: {
            _id: '$userId',
            email: { $first: '$userEmail' },
            totalOrders: { $sum: 1 },
            totalSpent: { $sum: '$totalAmount' },
            totalItems: { $sum: '$quantity' },
            lastOrderDate: { $max: '$createdAt' },
            firstOrderDate: { $min: '$createdAt' },
            products: { $addToSet: '$productName' },
          },
        },
        { $match: { totalOrders: { $gte: 2 } } },
        { $sort: { totalOrders: -1 } },
        { $limit: limit },
        {
          $project: {
            _id: 0,
            userId: '$_id',
            email: 1,
            totalOrders: 1,
            totalSpent: { $round: ['$totalSpent', 2] },
            totalItems: 1,
            lastOrderDate: 1,
            firstOrderDate: 1,
            uniqueProducts: { $size: '$products' },
          },
        },
      ]);

      // Lookup user names
      const enriched = await Promise.all(
        repeatedCustomers.map(async (customer) => {
          const user = await this.userDB.findById(customer.userId).select('name').lean();
          return {
            ...customer,
            name: user?.name || 'Unknown',
          };
        }),
      );

      const totalCustomersWithRepeatOrders = await this.orderDB.aggregate([
        { $match: { ...dateFilter, userId: { $ne: '' } } },
        { $group: { _id: '$userId', count: { $sum: 1 } } },
        { $match: { count: { $gte: 2 } } },
        { $count: 'total' },
      ]);

      return {
        success: true,
        message: 'Repeated customers retrieved successfully',
        data: {
          customers: enriched,
          totalRepeatedCustomers: totalCustomersWithRepeatOrders[0]?.total || 0,
        },
      };
    } catch (error) {
      throw new BadRequestException(error.message);
    }
  }
}
