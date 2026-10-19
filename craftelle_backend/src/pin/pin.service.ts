import { Injectable, BadRequestException, ForbiddenException, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Pin } from 'src/shared/schema/pin.schema';
import { CreatePinDto } from 'src/users/dto/create-pin.dto';
import { VerifyPinDto } from 'src/users/dto/verify-pin.dto';
import { UpdatePinDto } from 'src/users/dto/update-pin.dto';
import { PIN_LENGTH } from 'src/pin/pin.constants';
import * as bcrypt from 'bcrypt';

@Injectable()
export class PinService {
  private readonly logger = new Logger(PinService.name);
  private readonly MAX_ATTEMPTS = 3;
  private readonly LOCK_TIME = 15 * 60 * 1000; // 15 minutes lock time

  constructor(
    @InjectModel(Pin.name) private pinModel: Model<Pin>,
  ) {}

  async createPin(createPinDto: CreatePinDto & { phone: string }): Promise<{ message: string }> {
    const { userId, pin, phone } = createPinDto;

    if (!phone) {
      throw new BadRequestException('Phone number is required');
    }

    // Check if user already has a PIN
    const existingPin = await this.pinModel.findOne({ userId });
    if (existingPin) {
      throw new BadRequestException('PIN already exists for this user');
    }

    // Hash the PIN before storing
    const hashedPin = await bcrypt.hash(pin, 10);

    await this.pinModel.create({
      userId,
      pin: hashedPin,
      phone,
      attempts: 0,
      lastAttempt: null,
      lockedUntil: null,
    });

    return { message: 'PIN created successfully' };
  }

  async verifyPin(verifyPinDto: VerifyPinDto): Promise<{ success: boolean }> {
    const { userId, pin } = verifyPinDto;

    const userPin = await this.pinModel.findOne({ userId });
    if (!userPin) {
      throw new BadRequestException('No PIN found for this user');
    }

    // Check if PIN is locked
    if (userPin.lockedUntil && userPin.lockedUntil > new Date()) {
      throw new ForbiddenException(
        `PIN verification locked until ${userPin.lockedUntil}. Try again later.`,
      );
    }

    // Verify PIN
    const isPinValid = await bcrypt.compare(pin, userPin.pin);
    if (!isPinValid) {
      // Increment attempts
      userPin.attempts += 1;
      userPin.lastAttempt = new Date();

      // Lock if max attempts reached
      if (userPin.attempts >= this.MAX_ATTEMPTS) {
        userPin.lockedUntil = new Date(Date.now() + this.LOCK_TIME);
        await userPin.save();
        throw new ForbiddenException(
          `Too many failed attempts. PIN verification locked for ${this.LOCK_TIME / (60 * 1000)} minutes.`,
        );
      }

      await userPin.save();
      throw new BadRequestException('Invalid PIN');
    }

    // Reset attempts on successful verification
    userPin.attempts = 0;
    userPin.lastAttempt = null;
    userPin.lockedUntil = null;
    await userPin.save();

    return { success: true };
  }

  async updatePin(updatePinDto: UpdatePinDto & { phone: string }): Promise<{ message: string }> {
    const { userId, oldPin, newPin, phone } = updatePinDto;

    if (!phone) {
      throw new BadRequestException('Phone number is required');
    }

    const userPin = await this.pinModel.findOne({ userId });
    if (!userPin) {
      throw new BadRequestException('No PIN found for this user');
    }

    // Verify old PIN first
    const isOldPinValid = await bcrypt.compare(oldPin, userPin.pin);
    if (!isOldPinValid) {
      throw new BadRequestException('Old PIN is incorrect');
    }

    // Hash the new PIN
    const hashedNewPin = await bcrypt.hash(newPin, 10);

    // Update PIN and reset attempts
    userPin.pin = hashedNewPin;
    userPin.phone = phone;
    userPin.attempts = 0;
    userPin.lastAttempt = null;
    userPin.lockedUntil = null;
    await userPin.save();

    return { message: 'PIN updated successfully' };
  }

  async deletePin(userId: string): Promise<{ message: string }> {
    const result = await this.pinModel.deleteOne({ userId });
    if (result.deletedCount === 0) {
      throw new BadRequestException('No PIN found for this user');
    }

    return { message: 'PIN deleted successfully' };
  }

  async hasPin(userId: string): Promise<boolean> {
    const pin = await this.pinModel.findOne({ userId });
    return !!pin;
  }
}
