import { Injectable } from '@nestjs/common';
import * as nodemailer from 'nodemailer';
import * as path from 'path';
// eslint-disable-next-line @typescript-eslint/no-var-requires
const PDFDocument = require('pdfkit');

@Injectable()
export class EmailService {
  private transporter;
  private readonly logoPath = path.join(__dirname, 'craftelle-logo.png');

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
        rejectUnauthorized: false
      },
      connectionTimeout: 10000,
      greetingTimeout: 10000,
      socketTimeout: 10000,
    });
  }

  /**
   * Branded Craftelle email wrapper.
   * Wraps any body content in the Craftelle rose/pink themed email layout.
   */
  private craftelleEmailTemplate(bodyContent: string): string {
    return `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin: 0; padding: 0; background-color: #FFF1F2; font-family: 'Segoe UI', Arial, sans-serif;">
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color: #FFF1F2; padding: 30px 0;">
    <tr>
      <td align="center">
        <table role="presentation" width="600" cellpadding="0" cellspacing="0" style="max-width: 600px; width: 100%; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 24px rgba(251, 113, 133, 0.15);">

          <!-- Header with logo -->
          <tr>
            <td style="background: linear-gradient(135deg, #FDA4AF 0%, #FB7185 100%); padding: 32px 40px; text-align: center;">
              <img src="cid:craftelle-logo" alt="Craftelle" width="70" height="70" style="display: block; margin: 0 auto 12px; border-radius: 50%; background: rgba(255,255,255,0.2); padding: 4px;" />
              <h1 style="color: #ffffff; margin: 0; font-size: 28px; letter-spacing: 3px; font-weight: 700;">CRAFTELLE</h1>
              <p style="color: rgba(255,255,255,0.85); margin: 6px 0 0; font-size: 13px; letter-spacing: 1px;">Premium Gifting Brand</p>
            </td>
          </tr>

          <!-- Body content -->
          <tr>
            <td style="padding: 36px 40px;">
              ${bodyContent}
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background: #FFF1F2; padding: 24px 40px; text-align: center; border-top: 1px solid #FECDD3;">
              <p style="color: #FB7185; font-size: 13px; font-weight: 600; margin: 0 0 6px;">Craftelle - Premium Gifting Brand</p>
              <p style="color: #9CA3AF; font-size: 11px; margin: 0; line-height: 1.5;">
                This is an automated email from Craftelle.<br/>
                Please do not reply to this email.
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>`;
  }

  /**
   * Returns the Craftelle logo CID attachment for use in all emails.
   */
  private getLogoAttachment() {
    return {
      filename: 'craftelle-logo.png',
      path: this.logoPath,
      cid: 'craftelle-logo',
    };
  }

  async sendOTPEmail(email: string, otp: string) {
    const bodyContent = `
      <h2 style="color: #1F2937; margin: 0 0 8px; font-size: 22px;">Email Verification</h2>
      <p style="color: #6B7280; font-size: 15px; line-height: 1.6; margin: 0 0 24px;">
        Welcome to Craftelle! Please use the verification code below to activate your account.
      </p>

      <div style="background: linear-gradient(135deg, #FFF1F2 0%, #FECDD3 100%); border-radius: 12px; padding: 24px; text-align: center; margin: 0 0 24px;">
        <p style="color: #6B7280; font-size: 12px; text-transform: uppercase; letter-spacing: 2px; margin: 0 0 8px;">Your OTP Code</p>
        <p style="color: #FB7185; font-size: 36px; font-weight: 700; letter-spacing: 8px; margin: 0;">${otp}</p>
      </div>

      <div style="background: #F9FAFB; border-radius: 8px; padding: 14px 18px; margin: 0 0 16px;">
        <p style="color: #6B7280; font-size: 13px; margin: 0; line-height: 1.5;">
          <strong style="color: #1F2937;">Note:</strong> This code will expire in <strong>10 minutes</strong>. If you didn't create a Craftelle account, you can safely ignore this email.
        </p>
      </div>
    `;

    const mailOptions = {
      from: `"Craftelle" <${process.env.SMTP_USER}>`,
      to: email,
      subject: 'Craftelle - Email Verification Code',
      html: this.craftelleEmailTemplate(bodyContent),
      attachments: [this.getLogoAttachment()],
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
    const bodyContent = `
      <h2 style="color: #1F2937; margin: 0 0 8px; font-size: 22px;">Password Reset</h2>
      <p style="color: #6B7280; font-size: 15px; line-height: 1.6; margin: 0 0 24px;">
        We received a request to reset your Craftelle account password. Your new temporary password is below.
      </p>

      <div style="background: linear-gradient(135deg, #FFF1F2 0%, #FECDD3 100%); border-radius: 12px; padding: 24px; text-align: center; margin: 0 0 24px;">
        <p style="color: #6B7280; font-size: 12px; text-transform: uppercase; letter-spacing: 2px; margin: 0 0 8px;">Your New Password</p>
        <p style="color: #FB7185; font-size: 24px; font-weight: 700; letter-spacing: 3px; margin: 0; word-break: break-all;">${newPassword}</p>
      </div>

      <div style="background: #F9FAFB; border-radius: 8px; padding: 14px 18px; margin: 0 0 16px;">
        <p style="color: #6B7280; font-size: 13px; margin: 0; line-height: 1.5;">
          <strong style="color: #1F2937;">Important:</strong> For your security, please change your password on the <strong>Settings Page</strong> after logging in. If you didn't request a password reset, please contact support immediately.
        </p>
      </div>
    `;

    const mailOptions = {
      from: `"Craftelle" <${process.env.SMTP_USER}>`,
      to: email,
      subject: 'Craftelle - Password Reset',
      html: this.craftelleEmailTemplate(bodyContent),
      attachments: [this.getLogoAttachment()],
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

      const itemsHtml = (order.items || []).map((item: any) => `
        <tr>
          <td style="padding: 10px 12px; color: #1F2937; font-size: 14px; border-bottom: 1px solid #FFF1F2;">${item.productName || ''}</td>
          <td style="padding: 10px 12px; color: #6B7280; font-size: 14px; text-align: center; border-bottom: 1px solid #FFF1F2;">${item.quantity || 1}</td>
          <td style="padding: 10px 12px; color: #FB7185; font-weight: 600; font-size: 14px; text-align: right; border-bottom: 1px solid #FFF1F2;">GHS ${(item.price || 0).toLocaleString()}</td>
        </tr>
      `).join('');

      const bodyContent = `
        <h2 style="color: #1F2937; margin: 0 0 8px; font-size: 22px;">Order Confirmed!</h2>
        <p style="color: #6B7280; font-size: 15px; line-height: 1.6; margin: 0 0 24px;">
          Thank you for your order! Your purchase has been confirmed and is being processed. Please find your receipt details below.
        </p>

        <!-- Order Summary -->
        <div style="background: linear-gradient(135deg, #FFF1F2 0%, #FECDD3 100%); border-radius: 12px; padding: 20px; margin: 0 0 24px;">
          <table style="width: 100%; border-collapse: collapse;">
            <tr>
              <td style="padding: 6px 0; color: #6B7280; font-size: 14px;">Date</td>
              <td style="padding: 6px 0; color: #1F2937; font-weight: 600; text-align: right; font-size: 14px;">${orderDate}</td>
            </tr>
            <tr>
              <td style="padding: 6px 0; color: #6B7280; font-size: 14px;">Items</td>
              <td style="padding: 6px 0; color: #1F2937; font-weight: 600; text-align: right; font-size: 14px;">${(order.items || []).length} item(s)</td>
            </tr>
            <tr>
              <td style="padding: 6px 0; color: #6B7280; font-size: 14px;">Payment</td>
              <td style="padding: 6px 0; color: #10B981; font-weight: 600; text-align: right; font-size: 14px;">${order.paymentStatus || 'Pending'}</td>
            </tr>
            <tr>
              <td style="padding: 8px 0 0; color: #6B7280; font-size: 14px; border-top: 1px solid rgba(251,113,133,0.2);">Total</td>
              <td style="padding: 8px 0 0; color: #FB7185; font-weight: 700; text-align: right; font-size: 20px; border-top: 1px solid rgba(251,113,133,0.2);">GHS ${(order.totalPrice || 0).toLocaleString()}</td>
            </tr>
          </table>
        </div>

        <!-- Items Table -->
        ${(order.items || []).length > 0 ? `
        <table style="width: 100%; border-collapse: collapse; margin: 0 0 24px;">
          <thead>
            <tr style="background: #FB7185;">
              <th style="padding: 10px 12px; color: #fff; font-size: 13px; text-align: left; font-weight: 600;">Product</th>
              <th style="padding: 10px 12px; color: #fff; font-size: 13px; text-align: center; font-weight: 600;">Qty</th>
              <th style="padding: 10px 12px; color: #fff; font-size: 13px; text-align: right; font-weight: 600;">Price</th>
            </tr>
          </thead>
          <tbody>
            ${itemsHtml}
          </tbody>
        </table>
        ` : ''}

        <!-- Delivery Info -->
        <div style="background: #F9FAFB; border-radius: 8px; padding: 14px 18px; margin: 0 0 16px;">
          <p style="color: #1F2937; font-size: 13px; font-weight: 600; margin: 0 0 8px;">Delivery Details</p>
          <p style="color: #6B7280; font-size: 13px; margin: 0; line-height: 1.6;">
            ${order.deliveryAddress ? `${order.deliveryAddress}, ` : ''}${order.deliveryCity || ''}, ${order.deliveryRegion || ''}<br/>
            ${order.customerPhone ? `Phone: ${order.customerPhone}` : ''}
          </p>
        </div>

        <p style="color: #6B7280; font-size: 13px; line-height: 1.5; margin: 16px 0 0;">
          Your detailed receipt is attached as a PDF. If you have any questions, feel free to contact us.
        </p>
      `;

      const mailOptions = {
        from: `"Craftelle" <${process.env.SMTP_USER}>`,
        to: order.customerEmail,
        subject: 'Craftelle - Order Receipt',
        html: this.craftelleEmailTemplate(bodyContent),
        attachments: [
          this.getLogoAttachment(),
          {
            filename: 'Craftelle-Receipt.pdf',
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

  async sendNewQuoteOrderToSeller(order: any, sellerEmail: string) {
    try {
      const orderDate = order.createdAt
        ? new Date(order.createdAt).toLocaleDateString('en-GB', { day: 'numeric', month: 'long', year: 'numeric' })
        : new Date().toLocaleDateString('en-GB', { day: 'numeric', month: 'long', year: 'numeric' });

      const itemsHtml = (order.items || []).map((item: any) => `
        <tr>
          <td style="padding: 10px 12px; color: #1F2937; font-size: 14px; border-bottom: 1px solid #FFF1F2;">${item.productName || ''}</td>
          <td style="padding: 10px 12px; color: #6B7280; font-size: 14px; text-align: center; border-bottom: 1px solid #FFF1F2;">${item.quantity || 1}</td>
          <td style="padding: 10px 12px; color: #FB7185; font-weight: 600; font-size: 14px; text-align: right; border-bottom: 1px solid #FFF1F2;">GHS ${(item.price || 0).toLocaleString()}</td>
        </tr>
      `).join('');

      const extrasHtml = (order.wishListItems || []).map((item: any) => `
        <tr>
          <td style="padding: 10px 12px; color: #1F2937; font-size: 14px; border-bottom: 1px solid #FFF1F2;">${item.text || ''}</td>
          <td style="padding: 10px 12px; color: #6B7280; font-size: 13px; border-bottom: 1px solid #FFF1F2;">${item.specifications || '-'}</td>
        </tr>
      `).join('');

      const bodyContent = `
        <h2 style="color: #1F2937; margin: 0 0 8px; font-size: 22px;">New Order Requires Pricing!</h2>
        <p style="color: #6B7280; font-size: 15px; line-height: 1.6; margin: 0 0 24px;">
          A customer has placed an order that includes custom extras. Please review and price the extras in the Craftelle app.
        </p>

        <div style="background: linear-gradient(135deg, #FFF1F2 0%, #FECDD3 100%); border-radius: 12px; padding: 20px; margin: 0 0 24px;">
          <table style="width: 100%; border-collapse: collapse;">
            <tr>
              <td style="padding: 6px 0; color: #6B7280; font-size: 14px;">Date</td>
              <td style="padding: 6px 0; color: #1F2937; font-weight: 600; text-align: right; font-size: 14px;">${orderDate}</td>
            </tr>
            <tr>
              <td style="padding: 6px 0; color: #6B7280; font-size: 14px;">Customer</td>
              <td style="padding: 6px 0; color: #1F2937; font-weight: 600; text-align: right; font-size: 14px;">${order.customerEmail || ''}</td>
            </tr>
            <tr>
              <td style="padding: 6px 0; color: #6B7280; font-size: 14px;">Phone</td>
              <td style="padding: 6px 0; color: #1F2937; font-weight: 600; text-align: right; font-size: 14px;">${order.customerPhone || ''}</td>
            </tr>
            <tr>
              <td style="padding: 6px 0; color: #6B7280; font-size: 14px;">Status</td>
              <td style="padding: 6px 0; color: #F59E0B; font-weight: 600; text-align: right; font-size: 14px;">Awaiting Quote</td>
            </tr>
          </table>
        </div>

        ${(order.items || []).length > 0 ? `
        <h3 style="color: #1F2937; font-size: 16px; margin: 0 0 12px;">Basket Items</h3>
        <table style="width: 100%; border-collapse: collapse; margin: 0 0 20px;">
          <thead>
            <tr style="background: #FB7185;">
              <th style="padding: 10px 12px; color: #fff; font-size: 13px; text-align: left;">Product</th>
              <th style="padding: 10px 12px; color: #fff; font-size: 13px; text-align: center;">Qty</th>
              <th style="padding: 10px 12px; color: #fff; font-size: 13px; text-align: right;">Price</th>
            </tr>
          </thead>
          <tbody>${itemsHtml}</tbody>
        </table>
        ` : ''}

        <h3 style="color: #1F2937; font-size: 16px; margin: 0 0 12px;">Extras Needing Pricing</h3>
        <table style="width: 100%; border-collapse: collapse; margin: 0 0 24px;">
          <thead>
            <tr style="background: #F59E0B;">
              <th style="padding: 10px 12px; color: #fff; font-size: 13px; text-align: left;">Item</th>
              <th style="padding: 10px 12px; color: #fff; font-size: 13px; text-align: left;">Specifications</th>
            </tr>
          </thead>
          <tbody>${extrasHtml}</tbody>
        </table>

        <div style="background: #F9FAFB; border-radius: 8px; padding: 14px 18px; margin: 0 0 16px;">
          <p style="color: #6B7280; font-size: 13px; margin: 0; line-height: 1.5;">
            <strong style="color: #1F2937;">Action Required:</strong> Open the Craftelle app, go to <strong>Orders</strong>, and price each extra item. The customer will be notified once you send the quote.
          </p>
        </div>
      `;

      const mailOptions = {
        from: `"Craftelle" <${process.env.SMTP_USER}>`,
        to: sellerEmail,
        subject: 'Craftelle - New Order Requires Pricing',
        html: this.craftelleEmailTemplate(bodyContent),
        attachments: [this.getLogoAttachment()],
      };

      const info = await this.transporter.sendMail(mailOptions);
      console.log(`New quote order email sent to seller ${sellerEmail}: ${info.messageId}`);
      return { success: true, message: 'Seller notification email sent' };
    } catch (error) {
      console.error('Failed to send new quote order email to seller:', error);
      return { success: false, message: error.message };
    }
  }

  async sendQuoteEmail(order: any) {
    try {
      const pdfBuffer = await this.generateQuotePDF(order);

      const extrasHtml = (order.wishListItems || []).map((item: any) => `
        <tr>
          <td style="padding: 10px 12px; color: #1F2937; font-size: 14px; border-bottom: 1px solid #FFF1F2;">${item.text || ''}</td>
          <td style="padding: 10px 12px; color: #6B7280; font-size: 13px; border-bottom: 1px solid #FFF1F2;">${item.specifications || '-'}</td>
          <td style="padding: 10px 12px; color: #FB7185; font-weight: 600; font-size: 14px; text-align: right; border-bottom: 1px solid #FFF1F2;">GHS ${(item.quotedPrice || 0).toLocaleString()}</td>
        </tr>
      `).join('');

      const itemsHtml = (order.items || []).map((item: any) => `
        <tr>
          <td style="padding: 10px 12px; color: #1F2937; font-size: 14px; border-bottom: 1px solid #FFF1F2;">${item.productName || ''}</td>
          <td style="padding: 10px 12px; color: #6B7280; font-size: 14px; text-align: center; border-bottom: 1px solid #FFF1F2;">${item.quantity || 1}</td>
          <td style="padding: 10px 12px; color: #FB7185; font-weight: 600; font-size: 14px; text-align: right; border-bottom: 1px solid #FFF1F2;">GHS ${(item.price || 0).toLocaleString()}</td>
        </tr>
      `).join('');

      const bodyContent = `
        <h2 style="color: #1F2937; margin: 0 0 8px; font-size: 22px;">Your Quote is Ready!</h2>
        <p style="color: #6B7280; font-size: 15px; line-height: 1.6; margin: 0 0 24px;">
          Great news! The seller has reviewed your custom extras and provided pricing. Please review the details below and proceed to payment in the Craftelle app.
        </p>

        ${(order.items || []).length > 0 ? `
        <h3 style="color: #1F2937; font-size: 16px; margin: 0 0 12px;">Basket Items</h3>
        <table style="width: 100%; border-collapse: collapse; margin: 0 0 20px;">
          <thead>
            <tr style="background: #FB7185;">
              <th style="padding: 10px 12px; color: #fff; font-size: 13px; text-align: left;">Product</th>
              <th style="padding: 10px 12px; color: #fff; font-size: 13px; text-align: center;">Qty</th>
              <th style="padding: 10px 12px; color: #fff; font-size: 13px; text-align: right;">Price</th>
            </tr>
          </thead>
          <tbody>${itemsHtml}</tbody>
        </table>
        ` : ''}

        <h3 style="color: #1F2937; font-size: 16px; margin: 0 0 12px;">Quoted Extras</h3>
        <table style="width: 100%; border-collapse: collapse; margin: 0 0 24px;">
          <thead>
            <tr style="background: #FB7185;">
              <th style="padding: 10px 12px; color: #fff; font-size: 13px; text-align: left;">Item</th>
              <th style="padding: 10px 12px; color: #fff; font-size: 13px; text-align: left;">Specifications</th>
              <th style="padding: 10px 12px; color: #fff; font-size: 13px; text-align: right;">Price</th>
            </tr>
          </thead>
          <tbody>${extrasHtml}</tbody>
        </table>

        <div style="background: linear-gradient(135deg, #FFF1F2 0%, #FECDD3 100%); border-radius: 12px; padding: 20px; margin: 0 0 24px; text-align: center;">
          <p style="color: #6B7280; font-size: 12px; text-transform: uppercase; letter-spacing: 2px; margin: 0 0 8px;">Grand Total</p>
          <p style="color: #FB7185; font-size: 28px; font-weight: 700; margin: 0;">GHS ${(order.totalPrice || 0).toLocaleString()}</p>
        </div>

        <p style="color: #6B7280; font-size: 13px; line-height: 1.5;">
          Open the <strong>Craftelle</strong> app and go to your Orders to review and pay. Your detailed quote is attached as a PDF.
        </p>
      `;

      const mailOptions = {
        from: `"Craftelle" <${process.env.SMTP_USER}>`,
        to: order.customerEmail,
        subject: 'Craftelle - Your Quote is Ready',
        html: this.craftelleEmailTemplate(bodyContent),
        attachments: [
          this.getLogoAttachment(),
          {
            filename: 'Craftelle-Quote.pdf',
            content: pdfBuffer,
            contentType: 'application/pdf',
          },
        ],
      };

      const info = await this.transporter.sendMail(mailOptions);
      console.log(`Quote email sent to ${order.customerEmail}: ${info.messageId}`);
      return { success: true, message: 'Quote email sent' };
    } catch (error) {
      console.error('Failed to send quote email:', error);
      return { success: false, message: error.message };
    }
  }

  async sendFinalInvoiceEmail(order: any) {
    try {
      const pdfBuffer = await this.generateFinalInvoicePDF(order);

      const itemsHtml = (order.items || []).map((item: any) => `
        <tr>
          <td style="padding: 10px 12px; color: #1F2937; font-size: 14px; border-bottom: 1px solid #FFF1F2;">${item.productName || ''}</td>
          <td style="padding: 10px 12px; color: #6B7280; font-size: 14px; text-align: center; border-bottom: 1px solid #FFF1F2;">${item.quantity || 1}</td>
          <td style="padding: 10px 12px; color: #FB7185; font-weight: 600; font-size: 14px; text-align: right; border-bottom: 1px solid #FFF1F2;">GHS ${(item.price || 0).toLocaleString()}</td>
        </tr>
      `).join('');

      const extrasHtml = (order.wishListItems || []).filter((w: any) => w.quotedPrice).map((item: any) => `
        <tr>
          <td style="padding: 10px 12px; color: #1F2937; font-size: 14px; border-bottom: 1px solid #FFF1F2;">${item.text || ''}</td>
          <td style="padding: 10px 12px; color: #FB7185; font-weight: 600; font-size: 14px; text-align: right; border-bottom: 1px solid #FFF1F2;">GHS ${(item.quotedPrice || 0).toLocaleString()}</td>
        </tr>
      `).join('');

      const bodyContent = `
        <h2 style="color: #1F2937; margin: 0 0 8px; font-size: 22px;">Payment Confirmed!</h2>
        <p style="color: #6B7280; font-size: 15px; line-height: 1.6; margin: 0 0 24px;">
          Payment has been received and confirmed. Here is the final invoice for this order.
        </p>

        <div style="background: linear-gradient(135deg, #FFF1F2 0%, #FECDD3 100%); border-radius: 12px; padding: 20px; margin: 0 0 24px;">
          <table style="width: 100%; border-collapse: collapse;">
            <tr>
              <td style="padding: 6px 0; color: #6B7280; font-size: 14px;">Customer</td>
              <td style="padding: 6px 0; color: #1F2937; font-weight: 600; text-align: right; font-size: 14px;">${order.customerEmail || ''}</td>
            </tr>
            <tr>
              <td style="padding: 6px 0; color: #6B7280; font-size: 14px;">Payment Status</td>
              <td style="padding: 6px 0; color: #10B981; font-weight: 600; text-align: right; font-size: 14px;">Paid</td>
            </tr>
            <tr>
              <td style="padding: 6px 0; color: #6B7280; font-size: 14px;">Reference</td>
              <td style="padding: 6px 0; color: #1F2937; font-weight: 600; text-align: right; font-size: 14px;">${order.paymentReference || 'N/A'}</td>
            </tr>
            <tr>
              <td style="padding: 8px 0 0; color: #6B7280; font-size: 14px; border-top: 1px solid rgba(251,113,133,0.2);">Total Paid</td>
              <td style="padding: 8px 0 0; color: #FB7185; font-weight: 700; text-align: right; font-size: 20px; border-top: 1px solid rgba(251,113,133,0.2);">GHS ${(order.totalPrice || 0).toLocaleString()}</td>
            </tr>
          </table>
        </div>

        ${(order.items || []).length > 0 ? `
        <table style="width: 100%; border-collapse: collapse; margin: 0 0 16px;">
          <thead>
            <tr style="background: #FB7185;">
              <th style="padding: 10px 12px; color: #fff; font-size: 13px; text-align: left;">Product</th>
              <th style="padding: 10px 12px; color: #fff; font-size: 13px; text-align: center;">Qty</th>
              <th style="padding: 10px 12px; color: #fff; font-size: 13px; text-align: right;">Price</th>
            </tr>
          </thead>
          <tbody>${itemsHtml}</tbody>
        </table>
        ` : ''}

        ${extrasHtml ? `
        <table style="width: 100%; border-collapse: collapse; margin: 0 0 24px;">
          <thead>
            <tr style="background: #FB7185;">
              <th style="padding: 10px 12px; color: #fff; font-size: 13px; text-align: left;">Custom Extra</th>
              <th style="padding: 10px 12px; color: #fff; font-size: 13px; text-align: right;">Price</th>
            </tr>
          </thead>
          <tbody>${extrasHtml}</tbody>
        </table>
        ` : ''}

        <p style="color: #6B7280; font-size: 13px; line-height: 1.5;">
          Your final invoice is attached as a PDF. Thank you for choosing Craftelle!
        </p>
      `;

      // Send to customer and seller (sellerEmail is always resolved fresh from Users DB)
      const recipients = [order.customerEmail];
      if (order.sellerEmail) recipients.push(order.sellerEmail);

      const mailOptions = {
        from: `"Craftelle" <${process.env.SMTP_USER}>`,
        to: recipients.join(', '),
        subject: 'Craftelle - Payment Confirmed - Final Invoice',
        html: this.craftelleEmailTemplate(bodyContent),
        attachments: [
          this.getLogoAttachment(),
          {
            filename: 'Craftelle-Invoice.pdf',
            content: pdfBuffer,
            contentType: 'application/pdf',
          },
        ],
      };

      const info = await this.transporter.sendMail(mailOptions);
      console.log(`Final invoice sent to ${recipients.join(', ')}: ${info.messageId}`);
      return { success: true, message: 'Invoice email sent' };
    } catch (error) {
      console.error('Failed to send final invoice email:', error);
      return { success: false, message: error.message };
    }
  }

  private generateQuotePDF(order: any): Promise<Buffer> {
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

      // Header with logo
      doc.rect(0, 0, doc.page.width, 110).fill(pink);
      try { doc.image(this.logoPath, (doc.page.width - 40) / 2, 8, { width: 40, height: 40 }); } catch (e) {}
      doc.fontSize(28).fill('#FFFFFF').text('CRAFTELLE', 50, 52, { align: 'center' });
      doc.fontSize(11).fill('rgba(255,255,255,0.85)').text('Premium Gifting Brand', 50, 82, { align: 'center' });

      // Title
      doc.fill(darkText).fontSize(20).text('Quote', 50, 130);
      doc.moveTo(50, 158).lineTo(545, 158).strokeColor('#E5E7EB').stroke();

      let y = 175;
      const orderDate = order.quotedAt
        ? new Date(order.quotedAt).toLocaleDateString('en-GB', { day: 'numeric', month: 'long', year: 'numeric' })
        : new Date().toLocaleDateString('en-GB', { day: 'numeric', month: 'long', year: 'numeric' });

      const infoRows = [
        ['Date', orderDate],
        ['Customer', order.customerEmail || ''],
        ['Phone', order.customerPhone || ''],
        ['Delivery', `${order.deliveryAddress || ''}, ${order.deliveryCity || ''}, ${order.deliveryRegion || ''}`],
      ];

      for (const [label, value] of infoRows) {
        doc.fontSize(10).fill(grey).text(label, 50, y);
        doc.fontSize(10).fill(darkText).text(value as string, 180, y);
        y += 20;
      }

      // Basket items
      const items = order.items || [];
      if (items.length > 0) {
        y += 10;
        doc.fontSize(12).fill(darkText).text('Basket Items', 50, y);
        y += 20;
        doc.rect(50, y, 495, 25).fill(pink);
        doc.fontSize(10).fill('#FFFFFF');
        doc.text('Product', 60, y + 7);
        doc.text('Qty', 380, y + 7);
        doc.text('Price', 440, y + 7);
        y += 25;

        for (let i = 0; i < items.length; i++) {
          const item = items[i];
          const bgColor = i % 2 === 0 ? lightPink : '#FFFFFF';
          doc.rect(50, y, 495, 22).fill(bgColor);
          doc.fontSize(9).fill(darkText);
          doc.text(item.productName || '', 60, y + 6, { width: 310, ellipsis: true });
          doc.text(String(item.quantity || 1), 380, y + 6);
          doc.text(`GHS ${(item.price || 0).toLocaleString()}`, 440, y + 6);
          y += 22;
        }
      }

      // Quoted extras
      const wishList = order.wishListItems || [];
      if (wishList.length > 0) {
        y += 15;
        doc.fontSize(12).fill(darkText).text('Quoted Extras', 50, y);
        y += 20;
        doc.rect(50, y, 495, 25).fill(pink);
        doc.fontSize(10).fill('#FFFFFF');
        doc.text('Item', 60, y + 7);
        doc.text('Specifications', 250, y + 7);
        doc.text('Price', 440, y + 7);
        y += 25;

        for (let i = 0; i < wishList.length; i++) {
          const wish = wishList[i];
          const bgColor = i % 2 === 0 ? lightPink : '#FFFFFF';
          doc.rect(50, y, 495, 22).fill(bgColor);
          doc.fontSize(9).fill(darkText);
          doc.text(wish.text || '', 60, y + 6, { width: 180, ellipsis: true });
          doc.text(wish.specifications || '-', 250, y + 6, { width: 180, ellipsis: true });
          doc.text(`GHS ${(wish.quotedPrice || 0).toLocaleString()}`, 440, y + 6);
          y += 22;
        }
      }

      // Grand total
      y += 15;
      doc.moveTo(50, y).lineTo(545, y).strokeColor('#E5E7EB').stroke();
      y += 12;
      doc.rect(350, y, 195, 30).fill(pink);
      doc.fontSize(14).fill('#FFFFFF').text(`Total: GHS ${(order.totalPrice || 0).toLocaleString()}`, 360, y + 8);

      y += 55;
      doc.fontSize(10).fill(grey).text('Please pay via the Craftelle app to confirm your order.', 50, y, { align: 'center' });

      doc.end();
    });
  }

  private generateFinalInvoicePDF(order: any): Promise<Buffer> {
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

      // Header with logo
      doc.rect(0, 0, doc.page.width, 110).fill(pink);
      try { doc.image(this.logoPath, (doc.page.width - 40) / 2, 8, { width: 40, height: 40 }); } catch (e) {}
      doc.fontSize(28).fill('#FFFFFF').text('CRAFTELLE', 50, 52, { align: 'center' });
      doc.fontSize(11).fill('rgba(255,255,255,0.85)').text('Premium Gifting Brand', 50, 82, { align: 'center' });

      // Title
      doc.fill(darkText).fontSize(20).text('Final Invoice', 50, 130);
      doc.fill('#10B981').fontSize(12).text('PAID', 480, 135);
      doc.moveTo(50, 158).lineTo(545, 158).strokeColor('#E5E7EB').stroke();

      let y = 175;
      const orderDate = order.createdAt
        ? new Date(order.createdAt).toLocaleDateString('en-GB', { day: 'numeric', month: 'long', year: 'numeric' })
        : new Date().toLocaleDateString('en-GB', { day: 'numeric', month: 'long', year: 'numeric' });

      const infoRows = [
        ['Date', orderDate],
        ['Customer', order.customerEmail || ''],
        ['Phone', order.customerPhone || ''],
        ['Delivery', `${order.deliveryAddress || ''}, ${order.deliveryCity || ''}, ${order.deliveryRegion || ''}`],
        ['Payment Status', 'Paid'],
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

      // Items
      const items = order.items || [];
      if (items.length > 0) {
        doc.rect(50, y, 495, 25).fill(pink);
        doc.fontSize(10).fill('#FFFFFF');
        doc.text('Product', 60, y + 7);
        doc.text('Size', 300, y + 7);
        doc.text('Qty', 380, y + 7);
        doc.text('Price', 440, y + 7);
        y += 25;

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
      }

      // Extras
      const wishList = (order.wishListItems || []).filter((w: any) => w.quotedPrice);
      if (wishList.length > 0) {
        y += 10;
        doc.fontSize(10).fill(grey).text('Custom Extras:', 50, y);
        y += 16;
        for (const wish of wishList) {
          doc.fontSize(9).fill(darkText).text(`  - ${wish.text || ''}`, 60, y);
          doc.fill(pink).text(`GHS ${(wish.quotedPrice || 0).toLocaleString()}`, 440, y);
          y += 14;
        }
      }

      // Total
      y += 15;
      doc.moveTo(50, y).lineTo(545, y).strokeColor('#E5E7EB').stroke();
      y += 12;
      doc.rect(350, y, 195, 30).fill(pink);
      doc.fontSize(14).fill('#FFFFFF').text(`Total: GHS ${(order.totalPrice || 0).toLocaleString()}`, 360, y + 8);

      y += 55;
      doc.fontSize(10).fill(grey).text('Thank you for choosing Craftelle!', 50, y, { align: 'center' });

      doc.end();
    });
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

      // --- Header with logo ---
      doc.rect(0, 0, doc.page.width, 110).fill(pink);
      try { doc.image(this.logoPath, (doc.page.width - 40) / 2, 8, { width: 40, height: 40 }); } catch (e) {}
      doc.fontSize(28).fill('#FFFFFF').text('CRAFTELLE', 50, 52, { align: 'center' });
      doc.fontSize(11).fill('rgba(255,255,255,0.85)').text('Premium Gifting Brand', 50, 82, { align: 'center' });

      // --- Title ---
      doc.fill(darkText).fontSize(20).text('Order Receipt', 50, 130);
      doc.moveTo(50, 158).lineTo(545, 158).strokeColor('#E5E7EB').stroke();

      // --- Order Info ---
      let y = 175;
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

      doc.end();
    });
  }
}
