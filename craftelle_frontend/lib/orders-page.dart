import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'order-service.dart';
import 'craftelle-dialog.dart';
import 'paystack-checkout-page.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({Key? key}) : super(key: key);

  @override
  _OrdersPageState createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  static const _pink = Color(0xFFFDA4AF);
  static const _pinkDark = Color(0xFFFB7185);
  static const _bg = Color(0xFFFFF1F2);

  final _orderService = OrderService();

  @override
  void initState() {
    super.initState();
    _orderService.addListener(_onOrdersChanged);
  }

  void _onOrdersChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _orderService.removeListener(_onOrdersChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orders = _orderService.orders;

    return Container(
      color: _bg,
      child: orders.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: orders.length,
              itemBuilder: (context, index) => _buildOrderCard(orders[index], index),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _pink.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: _pink.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Orders Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your order history will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order, int index) {
    final dateStr = DateFormat('MMM d, yyyy - h:mm a').format(order.createdAt);
    final orderNum = _orderService.orders.length - index;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _pink.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_pink, _pinkDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(17)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.receipt, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #$orderNum',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'GHS ${NumberFormat('#,##0').format(order.totalPrice)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Basket Items
          if (order.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shopping_basket, size: 16, color: _pinkDark),
                      const SizedBox(width: 6),
                      const Text(
                        'Items',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...order.items.map((item) => _buildOrderItemRow(item)),
                ],
              ),
            ),

          // Wish List Items (with quoted prices when available)
          if (order.wishListItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.list_alt, size: 16, color: _pinkDark),
                      const SizedBox(width: 6),
                      const Text(
                        'Extras',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                      if (order.quoteStatus == 'pending') ...[
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Awaiting Quote',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...order.wishListItems.map((item) => _buildWishRow(item)),
                ],
              ),
            ),

          // Quote status badges + Pay Now button
          if (order.quoteStatus == 'quoted')
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: GestureDetector(
                onTap: () => _payForQuote(order),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_pink, _pinkDark]),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: _pinkDark.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.payment, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Pay Now — GHS ${NumberFormat('#,##0').format(order.totalPrice)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Order Status + Delete
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Row(
              children: [
                if (order.quoteStatus == 'pending')
                  _buildQuoteStatusBadge('Awaiting Quote', Colors.amber)
                else if (order.quoteStatus == 'quoted')
                  _buildQuoteStatusBadge('Quote Ready', Colors.blue)
                else if (order.quoteStatus == 'paid')
                  _buildQuoteStatusBadge('Paid', Colors.green)
                else
                  _buildOrderStatusBadge(order.orderStatus),
                const Spacer(),
                GestureDetector(
                  onTap: () => _confirmDelete(order),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete_outline, size: 16, color: Colors.red[400]),
                        const SizedBox(width: 4),
                        Text(
                          'Remove',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.red[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatusBadge(String status) {
    Color color;
    IconData icon;
    switch (status) {
      case 'Accepted':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'Rejected':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        color = Colors.orange;
        icon = Icons.hourglass_top;
        status = 'Pending';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemRow(OrderItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              item.imageUrl,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _pink.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.image, color: _pink.withOpacity(0.4), size: 20),
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.selectedSize != null)
                  Text(
                    item.displaySize,
                    style: TextStyle(
                      fontSize: 11,
                      color: _pinkDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '${item.quantity} × GHS ${NumberFormat('#,##0').format(item.price)}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: _pink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWishRow(OrderWishListItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: _pink,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.text,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF374151),
                    height: 1.4,
                  ),
                ),
                if (item.specifications.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _buildExtraTag(item.specifications),
                ],
              ],
            ),
          ),
          if (item.quotedPrice != null)
            Text(
              'GHS ${NumberFormat('#,##0').format(item.quotedPrice)}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: _pinkDark,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuoteStatusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            label == 'Paid' ? Icons.check_circle : Icons.request_quote,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Future<void> _payForQuote(Order order) async {
    const baseUrl = 'https://craftelle.fly.dev/api/v1';
    const callbackUrl = 'https://craftelle.app/payment/callback';

    try {
      final amountInPesewas = (order.totalPrice * 100).round();

      final initResponse = await http.post(
        Uri.parse('$baseUrl/paystack/initiate'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': order.customerEmail,
          'amount': amountInPesewas,
          'callbackUrl': callbackUrl,
        }),
      );

      if (initResponse.statusCode != 200 && initResponse.statusCode != 201) {
        throw Exception('Failed to initialize payment');
      }

      final initData = json.decode(initResponse.body);
      final paystackData = initData['result']?['data'] ?? initData['data'];
      final authorizationUrl = paystackData?['authorization_url'];

      if (authorizationUrl == null) throw Exception('No authorization URL');

      if (!mounted) return;

      final paymentReference = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) => PaystackCheckoutPage(
            authorizationUrl: authorizationUrl,
            callbackUrl: callbackUrl,
          ),
        ),
      );

      if (!mounted) return;

      if (paymentReference == null) {
        CraftelleDialog.showInfo(context, title: 'Cancelled', message: 'Payment was cancelled.');
        return;
      }

      // Pay the quote via backend
      final success = await OrderService().payQuote(order.id, paymentReference);

      if (success && mounted) {
        await _orderService.init(customerEmail: _orderService.customerEmail);
        CraftelleDialog.showSuccess(
          context,
          title: 'Payment Successful',
          message: 'Your payment has been confirmed! A final invoice has been sent to your email.',
        );
      } else if (mounted) {
        CraftelleDialog.showError(context, title: 'Error', message: 'Payment verification failed.');
      }
    } catch (e) {
      if (mounted) {
        CraftelleDialog.showError(
          context,
          title: 'Payment Failed',
          message: e.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }

  Widget _buildExtraTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _pink.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF6B7280),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _confirmDelete(Order order) async {
    final confirmed = await CraftelleDialog.showConfirmation(
      context,
      title: 'Remove Order',
      message: 'This order will be removed from your history. This action cannot be undone.',
      confirmText: 'Remove',
      cancelText: 'Cancel',
      isDangerous: true,
    );

    if (confirmed) {
      _orderService.removeOrder(order.id);
    }
  }
}
