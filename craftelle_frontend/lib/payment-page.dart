import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'basket-service.dart';
import 'order-service.dart';
import 'paystack-checkout-page.dart';

class PaymentPage extends StatefulWidget {
  final List<BasketItem> basketItems;
  final List<WishListItem> wishList;
  final double totalPrice;
  final String deliveryCity;
  final String deliveryRegion;
  final String deliveryAddress;
  final String customerPhone;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final VoidCallback onPaymentConfirmed;

  const PaymentPage({
    Key? key,
    required this.basketItems,
    required this.wishList,
    required this.totalPrice,
    required this.deliveryCity,
    required this.deliveryRegion,
    required this.deliveryAddress,
    required this.customerPhone,
    this.deliveryLatitude,
    this.deliveryLongitude,
    required this.onPaymentConfirmed,
  }) : super(key: key);

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  static const _pink = Color(0xFFFDA4AF);
  static const _pinkDark = Color(0xFFFB7185);
  static const _bg = Color(0xFFFFF1F2);
  static const _baseUrl = 'https://neurosense-palsy.fly.dev/api/v1';
  static const _callbackUrl = 'https://craftelle.app/payment/callback';

  bool _isLoading = false;

  Future<void> _payWithPaystack() async {
    setState(() => _isLoading = true);

    try {
      // Step 1: Initialize Paystack transaction via backend
      final customerEmail = OrderService().customerEmail;
      final amountInPesewas = (widget.totalPrice * 100).round();

      final initResponse = await http.post(
        Uri.parse('$_baseUrl/paystack/initiate'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': customerEmail,
          'amount': amountInPesewas,
          'callbackUrl': _callbackUrl,
          'metadata': {
            'customerPhone': widget.customerPhone,
            'deliveryCity': widget.deliveryCity,
            'deliveryRegion': widget.deliveryRegion,
          },
        }),
      );

      if (initResponse.statusCode != 200 && initResponse.statusCode != 201) {
        throw Exception('Failed to initialize payment');
      }

      final initData = json.decode(initResponse.body);
      final authorizationUrl = initData['data']?['authorization_url'];
      final reference = initData['data']?['reference'];

      if (authorizationUrl == null) {
        throw Exception('No authorization URL received');
      }

      if (!mounted) return;

      // Step 2: Open Paystack checkout in WebView
      final paymentReference = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) => PaystackCheckoutPage(
            authorizationUrl: authorizationUrl,
            callbackUrl: _callbackUrl,
          ),
        ),
      );

      if (!mounted) return;

      if (paymentReference == null) {
        // User cancelled the payment
        setState(() => _isLoading = false);
        _showSnackbar('Payment cancelled', Colors.orange);
        return;
      }

      // Step 3: Verify the payment
      final verifyResponse = await http.post(
        Uri.parse('$_baseUrl/paystack/verify?reference=$paymentReference'),
        headers: {'Content-Type': 'application/json'},
      );

      if (verifyResponse.statusCode != 200 && verifyResponse.statusCode != 201) {
        throw Exception('Payment verification failed');
      }

      final verifyData = json.decode(verifyResponse.body);
      final paymentStatus = verifyData['data']?['status'];
      final paidAmountPesewas = verifyData['data']?['amount'] as int?;
      final expectedAmountPesewas = amountInPesewas;

      if (paymentStatus != 'success') {
        throw Exception('Payment was not successful: $paymentStatus');
      }

      // Verify the paid amount matches the order total exactly
      if (paidAmountPesewas == null || paidAmountPesewas != expectedAmountPesewas) {
        final paidGHS = paidAmountPesewas != null
            ? (paidAmountPesewas / 100).toStringAsFixed(2)
            : '0.00';
        final expectedGHS = (expectedAmountPesewas / 100).toStringAsFixed(2);
        throw Exception(
          'Amount mismatch! Paid: GHS $paidGHS, Expected: GHS $expectedGHS. You must pay the exact order amount.',
        );
      }

      // Step 4: Payment successful & amount verified — save the order
      await OrderService().placeOrder(
        widget.basketItems,
        widget.wishList,
        deliveryCity: widget.deliveryCity,
        deliveryRegion: widget.deliveryRegion,
        deliveryAddress: widget.deliveryAddress,
        customerPhone: widget.customerPhone,
        deliveryLatitude: widget.deliveryLatitude,
        deliveryLongitude: widget.deliveryLongitude,
        paymentReference: paymentReference,
        paymentStatus: 'Paid',
      );

      widget.onPaymentConfirmed();

      if (mounted) {
        _showSnackbar('Payment successful! Order placed.', _pink);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showSnackbar('Error: $e', Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == Colors.red ? Icons.error : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Payment'),
        centerTitle: true,
        backgroundColor: _pink,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Summary Card
            _buildOrderSummaryCard(),
            const SizedBox(height: 20),

            // Delivery Info Card
            _buildDeliveryInfoCard(),
            const SizedBox(height: 20),

            // Payment Info Card
            _buildPaymentInfoCard(),
            const SizedBox(height: 24),

            // Pay Now Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _payWithPaystack,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _pinkDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_outline, size: 22),
                          SizedBox(width: 12),
                          Text(
                            'Pay Now',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),

            // Secure Payment Note
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shield_outlined, size: 14, color: Colors.grey[400]),
                  const SizedBox(width: 6),
                  Text(
                    'Secured by Paystack',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_pink, _pinkDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _pinkDark.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.receipt_long, color: Colors.white, size: 36),
          const SizedBox(height: 10),
          const Text(
            'Order Total',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'GHS ${NumberFormat('#,##0.00').format(widget.totalPrice)}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${widget.basketItems.length} item${widget.basketItems.length == 1 ? '' : 's'}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _pink.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.local_shipping_outlined, color: _pinkDark, size: 20),
              SizedBox(width: 8),
              Text(
                'Delivery Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildInfoRow(Icons.location_city, widget.deliveryCity),
          _buildInfoRow(Icons.map_outlined, widget.deliveryRegion),
          if (widget.deliveryAddress.isNotEmpty)
            _buildInfoRow(Icons.pin_drop_outlined, widget.deliveryAddress),
          _buildInfoRow(Icons.phone_outlined, widget.customerPhone),
        ],
      ),
    );
  }

  Widget _buildPaymentInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _pink.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _bg,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.payment, color: _pinkDark, size: 28),
          ),
          const SizedBox(height: 14),
          const Text(
            'Payment Method',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 10),
          // Payment options row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPaymentChip('Mobile Money', Icons.phone_android),
              const SizedBox(width: 10),
              _buildPaymentChip('Card', Icons.credit_card),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'You\'ll be redirected to Paystack to\ncomplete your payment securely',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _pink.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _pinkDark),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _pink),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
