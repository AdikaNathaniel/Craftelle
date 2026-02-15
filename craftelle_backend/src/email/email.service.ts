import { Injectable } from '@nestjs/common';
import * as nodemailer from 'nodemailer';
// eslint-disable-next-line @typescript-eslint/no-var-requires
const PDFDocument = require('pdfkit');

@Injectable()
export class EmailService {
  private transporter;

  constructor() {
    console.log("SMTP Configuration:", {
      host: process.env.SMTP_HOST,
      port: parseInt(process.env.SMTP_PORT),
      user: process.env.SMTP_USER,
      pass: process.env.SMTP_PASS ? "******" : "NOT SET",
    });
    
    this.transporter = nodemailer.createTransport({
      host: process.env.SMTP_HOST,
      port: parseInt(process.env.SMTP_PORT),
      secure: false, 
      auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASS,
      },
      tls: {
        rejectUnauthorized: false // ← ADD THIS LINE
      },
      connectionTimeout: 10000,
      greetingTimeout: 10000,
      socketTimeout: 10000,
    });
  }

  async sendOTPEmail(email: string, otp: string) {
    const mailOptions = {
      from: process.env.SMTP_USER,
      to: email,
      subject: 'Your OTP Verification Code',
      html: `
        <h1>OTP Verification</h1>
        <p>Your OTP code is: <strong>${otp}</strong></p>
        <p>This code will expire in 10 minutes.</p>
      `,
    };
    
    try {
      console.log(`Attempting to send OTP email to ${email}`);
      const info = await this.transporter.sendMail(mailOptions);
      console.log(`Email sent successfully: ${info.messageId}`);
      return { success: true, message: 'OTP sent successfully', messageId: info.messageId };
    } catch (error) {
      console.error("Failed to send email:", error);
      return { success: false, message: error.message };
    }
  }

  async onModuleInit() {
    try {
      console.log("Verifying email connection...");
      await this.transporter.verify();
      console.log("Email service is ready to send emails");
    } catch (error) {
      console.error("Failed to connect to email server:", error);
    }
  }

  async sendForgotPasswordEmail(email: string, newPassword: string) {
    const mailOptions = {
      from: process.env.SMTP_USER,
      to: email,
      subject: 'Your New Password',
      html: `
        <h1>Password Reset</h1>
        <p>Your new password is: <strong>${newPassword}</strong></p>
        <p>Please change your password on the settings Page after logging in.</p>
      `,
    };

    try {
      await this.transporter.sendMail(mailOptions);
      return { success: true, message: 'New password sent successfully' };
    } catch (error) {
      console.error('Email sending error:', error);
      return { success: false, message: error.message };
    }
  }

  async sendOrderReceiptEmail(order: any) {
    try {
      const pdfBuffer = await this.generateReceiptPDF(order);

      const orderDate = order.createdAt
        ? new Date(order.createdAt).toLocaleDateString('en-GB', {
            day: 'numeric',
            month: 'long',
            year: 'numeric',
          })
        : new Date().toLocaleDateString('en-GB', {
            day: 'numeric',
            month: 'long',
            year: 'numeric',
          });

      const mailOptions = {
        from: process.env.SMTP_USER,
        to: order.customerEmail,
        subject: `Craftelle - Order Receipt`,
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; background: #fff;">
            <div style="background: linear-gradient(135deg, #FDA4AF, #FB7185); padding: 30px; text-align: center; border-radius: 8px 8px 0 0;">
              <h1 style="color: white; margin: 0; font-size: 28px; letter-spacing: 2px;">CRAFTELLE</h1>
              <p style="color: rgba(255,255,255,0.9); margin: 8px 0 0; font-size: 14px;">Premium Gifting Brand</p>
            </div>
            <div style="padding: 30px; background: #fff;">
              <h2 style="color: #1F2937; margin-bottom: 8px;">Thank you for your order!</h2>
              <p style="color: #6B7280; font-size: 15px; line-height: 1.6;">
                Your order has been confirmed and is being processed. Please find your order receipt attached as a PDF.
              </p>
              <div style="background: #FFF1F2; border-radius: 12px; padding: 20px; margin: 20px 0;">
                <table style="width: 100%; border-collapse: collapse;">
                  <tr>
                    <td style="padding: 6px 0; color: #6B7280; font-size: 14px;">Date</td>
                    <td style="padding: 6px 0; color: #1F2937; font-weight: bold; text-align: right; font-size: 14px;">${orderDate}</td>
                  </tr>
                  <tr>
                    <td style="padding: 6px 0; color: #6B7280; font-size: 14px;">Total</td>
                    <td style="padding: 6px 0; color: #FB7185; font-weight: bold; text-align: right; font-size: 16px;">GHS ${(order.totalPrice || 0).toLocaleString()}</td>
                  </tr>
                  <tr>
                    <td style="padding: 6px 0; color: #6B7280; font-size: 14px;">Payment</td>
                    <td style="padding: 6px 0; color: #10B981; font-weight: bold; text-align: right; font-size: 14px;">${order.paymentStatus || 'Pending'}</td>
                  </tr>
                  <tr>
                    <td style="padding: 6px 0; color: #6B7280; font-size: 14px;">Items</td>
                    <td style="padding: 6px 0; color: #1F2937; font-weight: bold; text-align: right; font-size: 14px;">${(order.items || []).length} item(s)</td>
                  </tr>
                </table>
              </div>
              <p style="color: #6B7280; font-size: 13px; line-height: 1.5;">
                If you have any questions, feel free to contact us on WhatsApp or email.
              </p>
            </div>
            <div style="background: #F9FAFB; padding: 20px; text-align: center; border-radius: 0 0 8px 8px; border-top: 1px solid #E5E7EB;">
              <p style="color: #9CA3AF; font-size: 12px; margin: 0;">Craftelle - Premium Gifting Brand</p>
            </div>
          </div>
        `,
        attachments: [
          {
            filename: `Craftelle-Receipt.pdf`,
            content: pdfBuffer,
            contentType: 'application/pdf',
          },
        ],
      };

      const info = await this.transporter.sendMail(mailOptions);
      console.log(`Order receipt sent to ${order.customerEmail}: ${info.messageId}`);
      return { success: true, message: 'Receipt email sent' };
    } catch (error) {
      console.error('Failed to send order receipt email:', error);
      return { success: false, message: error.message };
    }
  }

  private generateReceiptPDF(order: any): Promise<Buffer> {
    return new Promise((resolve, reject) => {
      const doc = new PDFDocument({ size: 'A4', margin: 50 });
      const chunks: Buffer[] = [];

      doc.on('data', (chunk: Buffer) => chunks.push(chunk));
      doc.on('end', () => resolve(Buffer.concat(chunks)));
      doc.on('error', reject);

      const pink = '#FB7185';
      const darkText = '#1F2937';
      const grey = '#6B7280';
      const lightPink = '#FFF1F2';

      // --- Header ---
      doc.rect(0, 0, doc.page.width, 100).fill(pink);
      doc.fontSize(32).fill('#FFFFFF').text('CRAFTELLE', 50, 30, { align: 'center' });
      doc.fontSize(12).fill('rgba(255,255,255,0.85)').text('Premium Gifting Brand', 50, 65, { align: 'center' });

      // --- Title ---
      doc.fill(darkText).fontSize(20).text('Order Receipt', 50, 120);
      doc.moveTo(50, 148).lineTo(545, 148).strokeColor('#E5E7EB').stroke();

      // --- Order Info ---
      let y = 165;
      const orderDate = order.createdAt
        ? new Date(order.createdAt).toLocaleDateString('en-GB', {
            day: 'numeric',
            month: 'long',
            year: 'numeric',
          })
        : new Date().toLocaleDateString('en-GB', {
            day: 'numeric',
            month: 'long',
            year: 'numeric',
          });

      const infoRows = [
        ['Date', orderDate],
        ['Customer', order.customerEmail || ''],
        ['Phone', order.customerPhone || ''],
        ['Delivery', `${order.deliveryAddress || ''}, ${order.deliveryCity || ''}, ${order.deliveryRegion || ''}`],
        ['Payment Status', order.paymentStatus || 'Pending'],
        ['Payment Ref', order.paymentReference || 'N/A'],
      ];

      for (const [label, value] of infoRows) {
        doc.fontSize(10).fill(grey).text(label, 50, y);
        doc.fontSize(10).fill(darkText).text(value as string, 180, y);
        y += 20;
      }

      y += 10;
      doc.moveTo(50, y).lineTo(545, y).strokeColor('#E5E7EB').stroke();
      y += 15;

      // --- Items Table Header ---
      doc.rect(50, y, 495, 25).fill(pink);
      doc.fontSize(10).fill('#FFFFFF');
      doc.text('Product', 60, y + 7);
      doc.text('Size', 300, y + 7);
      doc.text('Qty', 380, y + 7);
      doc.text('Price', 440, y + 7);
      y += 25;

      // --- Items ---
      const items = order.items || [];
      for (let i = 0; i < items.length; i++) {
        const item = items[i];
        const bgColor = i % 2 === 0 ? lightPink : '#FFFFFF';
        doc.rect(50, y, 495, 22).fill(bgColor);
        doc.fontSize(9).fill(darkText);
        doc.text(item.productName || '', 60, y + 6, { width: 230, ellipsis: true });
        doc.text(item.selectedSize || '-', 300, y + 6);
        doc.text(String(item.quantity || 1), 380, y + 6);
        doc.text(`GHS ${(item.price || 0).toLocaleString()}`, 440, y + 6);
        y += 22;
      }

      // --- Wish List ---
      const wishList = order.wishListItems || [];
      if (wishList.length > 0) {
        y += 10;
        doc.fontSize(10).fill(grey).text('Wish List Items:', 50, y);
        y += 16;
        for (const wish of wishList) {
          doc.fontSize(9).fill(darkText).text(`  - ${wish}`, 60, y);
          y += 14;
        }
      }

      // --- Total ---
      y += 15;
      doc.moveTo(50, y).lineTo(545, y).strokeColor('#E5E7EB').stroke();
      y += 12;
      doc.rect(350, y, 195, 30).fill(pink);
      doc.fontSize(14).fill('#FFFFFF').text(`Total: GHS ${(order.totalPrice || 0).toLocaleString()}`, 360, y + 8);

      // --- Footer ---
      y += 55;
      doc.fontSize(10).fill(grey).text('Thank you for choosing Craftelle!', 50, y, { align: 'center' });
      doc.fontSize(8).fill('#9CA3AF').text('This is an auto-generated receipt.', 50, y + 18, { align: 'center' });

      doc.end();
    });
  }
}