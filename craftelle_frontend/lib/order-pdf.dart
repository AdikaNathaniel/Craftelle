import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'order-service.dart';

class OrderPdfGenerator {
  static const _pinkColor = PdfColor.fromInt(0xFFFDA4AF);
  static const _pinkDark = PdfColor.fromInt(0xFFFB7185);

  static Future<void> generateAndOpen(Order order, int orderNumber) async {
    final pdf = pw.Document();

    final logoBytes = await rootBundle.load('assets/craftelle.png');
    final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

    final dateStr = DateFormat('MMM d, yyyy - h:mm a').format(order.createdAt);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Logo + Title
              pw.Center(
                child: pw.ClipOval(
                  child: pw.Image(logoImage, width: 80, height: 80),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                  'Craftelle',
                  style: pw.TextStyle(
                    fontSize: 26,
                    fontWeight: pw.FontWeight.bold,
                    color: _pinkDark,
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  'Order Receipt',
                  style: pw.TextStyle(
                    fontSize: 14,
                    color: PdfColors.grey600,
                  ),
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Divider(color: _pinkColor, thickness: 2),
              pw.SizedBox(height: 14),

              // Order Info
              _infoRow('Order #', '$orderNumber'),
              _infoRow('Date', dateStr),
              _infoRow('Customer', order.customerEmail),
              if (order.customerPhone.isNotEmpty)
                _infoRow('Phone', order.customerPhone),
              pw.SizedBox(height: 12),

              // Delivery Location
              if (order.deliveryCity.isNotEmpty ||
                  order.deliveryRegion.isNotEmpty ||
                  order.deliveryAddress.isNotEmpty) ...[
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFFFF1F2),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    'Delivery Location',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: _pinkDark,
                    ),
                  ),
                ),
                pw.SizedBox(height: 6),
                if (order.deliveryCity.isNotEmpty)
                  _infoRow('City', order.deliveryCity),
                if (order.deliveryRegion.isNotEmpty)
                  _infoRow('Region', order.deliveryRegion),
                if (order.deliveryAddress.isNotEmpty)
                  _infoRow('Address', order.deliveryAddress),
                pw.SizedBox(height: 14),
              ],

              // Items Table
              if (order.items.isNotEmpty) ...[
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFFFF1F2),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    'Order Items',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: _pinkDark,
                    ),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3),
                    1: const pw.FlexColumnWidth(1.5),
                    2: const pw.FlexColumnWidth(1),
                    3: const pw.FlexColumnWidth(1.5),
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: _pinkColor),
                      children: [
                        _headerCell('Product'),
                        _headerCell('Size'),
                        _headerCell('Qty'),
                        _headerCell('Price (GHS)'),
                      ],
                    ),
                    ...order.items.map((item) => pw.TableRow(
                          children: [
                            _cell(item.productName),
                            _cell(item.displaySize.isEmpty
                                ? '-'
                                : item.displaySize),
                            _cell('${item.quantity}'),
                            _cell(NumberFormat('#,##0')
                                .format(item.price * item.quantity)),
                          ],
                        )),
                  ],
                ),
                pw.SizedBox(height: 14),
              ],

              // Wish List
              if (order.wishListItems.isNotEmpty) ...[
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFFFF1F2),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    'Wish List',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: _pinkDark,
                    ),
                  ),
                ),
                pw.SizedBox(height: 6),
                ...order.wishListItems.map((text) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 4),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('  -  ',
                              style: pw.TextStyle(color: _pinkDark)),
                          pw.Expanded(
                            child: pw.Text(text,
                                style: const pw.TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    )),
                pw.SizedBox(height: 14),
              ],

              // Total
              pw.Divider(color: _pinkColor, thickness: 1.5),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    'Total:  ',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'GHS ${NumberFormat('#,##0').format(order.totalPrice)}',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: _pinkDark,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    'Payment: ',
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.Text(
                    order.paymentStatus,
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: _pinkDark,
                    ),
                  ),
                ],
              ),

              pw.Spacer(),

              // Footer
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  'Thank you for shopping with Craftelle!',
                  style: pw.TextStyle(
                    fontSize: 11,
                    color: PdfColors.grey500,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Craftelle_Order_$orderNumber',
    );
  }

  static pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _headerCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  static pw.Widget _cell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 11)),
    );
  }
}
