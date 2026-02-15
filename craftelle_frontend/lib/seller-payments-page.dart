import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SellerPaymentsPage extends StatefulWidget {
  final String sellerEmail;

  const SellerPaymentsPage({Key? key, required this.sellerEmail})
      : super(key: key);

  @override
  _SellerPaymentsPageState createState() => _SellerPaymentsPageState();
}

class _SellerPaymentsPageState extends State<SellerPaymentsPage> {
  static const _pink = Color(0xFFFDA4AF);
  static const _pinkDark = Color(0xFFFB7185);
  static const _bg = Color(0xFFFFF1F2);
  static const _baseUrl = 'https://neurosense-palsy.fly.dev/api/v1/orders';

  List<dynamic> _orders = [];
  bool _isLoading = true;
  double _totalRevenue = 0;
  int _paidCount = 0;
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchPayments();
  }

  Future<void> _fetchPayments() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?sellerEmail=${widget.sellerEmail}'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = data['result'] ?? data;
        if (mounted) {
          final orders = result is List ? result : [];
          orders.sort((a, b) {
            final dateA = a['createdAt'] ?? '';
            final dateB = b['createdAt'] ?? '';
            return dateB.compareTo(dateA);
          });

          double revenue = 0;
          int paid = 0;
          int pending = 0;
          for (final order in orders) {
            final sellerTotal = _getSellerTotal(order);
            revenue += sellerTotal;
            final ps = (order['paymentStatus'] ?? 'Pending').toString().toLowerCase();
            if (ps == 'paid' || ps == 'completed' || ps == 'success') {
              paid++;
            } else {
              pending++;
            }
          }

          setState(() {
            _orders = orders;
            _totalRevenue = revenue;
            _paidCount = paid;
            _pendingCount = pending;
            _isLoading = false;
          });
        }
        return;
      }
    } catch (e) {
      debugPrint('Error fetching payments: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  double _getSellerTotal(dynamic order) {
    final items = order['items'] as List<dynamic>? ?? [];
    double total = 0;
    for (final item in items) {
      if (item['sellerEmail'] == widget.sellerEmail) {
        total += ((item['price'] ?? 0) as num).toDouble() *
            ((item['quantity'] ?? 1) as num).toInt();
      }
    }
    return total;
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  Color _paymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
      case 'completed':
      case 'success':
        return Colors.green;
      case 'failed':
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData _paymentStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
      case 'completed':
      case 'success':
        return Icons.check_circle;
      case 'failed':
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.schedule;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: RefreshIndicator(
        color: _pink,
        onRefresh: _fetchPayments,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _pink))
            : _orders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.payments_outlined,
                            size: 60, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text(
                          'No payments yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ..._orders.map((order) => _buildPaymentCard(order)),
                    ],
                  ),
      ),
    );
  }

  Widget _buildSummaryRow() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total Revenue',
            'GH\u20B5 ${_totalRevenue.toStringAsFixed(2)}',
            Icons.account_balance_wallet,
            _pinkDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSummaryCard(
            'Paid',
            '$_paidCount',
            Icons.check_circle_outline,
            Colors.green,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSummaryCard(
            'Pending',
            '$_pendingCount',
            Icons.schedule,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(dynamic order) {
    final items = order['items'] as List<dynamic>? ?? [];
    final sellerItems = items
        .where((item) => item['sellerEmail'] == widget.sellerEmail)
        .toList();
    final sellerTotal = _getSellerTotal(order);
    final paymentStatus = order['paymentStatus'] ?? 'Pending';
    final orderStatus = order['orderStatus'] ?? order['status'] ?? 'Pending';
    final createdAt = order['createdAt']?.toString();
    final customerEmail = order['customerEmail'] ?? '';
    final customerPhone = order['customerPhone'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _pink.withOpacity(0.15)),
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
          // Header with date + payment status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _pink.withOpacity(0.06),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(_paymentStatusIcon(paymentStatus),
                    color: _paymentStatusColor(paymentStatus), size: 18),
                const SizedBox(width: 8),
                Text(
                  _formatDate(createdAt),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _paymentStatusColor(paymentStatus).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    paymentStatus,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _paymentStatusColor(paymentStatus),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer info
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        customerEmail,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (customerPhone.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.phone_outlined,
                          size: 16, color: Colors.grey[500]),
                      const SizedBox(width: 6),
                      Text(
                        customerPhone,
                        style:
                            TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),

                // Items purchased from this seller
                ...sellerItems.map((item) {
                  final name = item['productName'] ?? 'Product';
                  final qty = item['quantity'] ?? 1;
                  final price = (item['price'] ?? 0).toDouble();
                  final size = item['selectedSize'] ?? '';
                  final imageUrl = item['imageUrl'] ?? '';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 40,
                                    height: 40,
                                    color: _pink.withOpacity(0.1),
                                    child: const Icon(Icons.image,
                                        color: _pink, size: 18),
                                  ),
                                )
                              : Container(
                                  width: 40,
                                  height: 40,
                                  color: _pink.withOpacity(0.1),
                                  child: const Icon(Icons.image,
                                      color: _pink, size: 18),
                                ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1F2937),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Qty: $qty${size.isNotEmpty ? ' · ${_displaySize(size)}' : ''}',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'GH\u20B5 ${(price * qty).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _pinkDark,
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const Divider(height: 20),

                // Total + order status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Your Earnings',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      'GH\u20B5 ${sellerTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _pinkDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.local_shipping_outlined,
                        size: 14, color: Colors.grey[400]),
                    const SizedBox(width: 6),
                    Text(
                      'Order: $orderStatus',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _displaySize(String sizeKey) {
    switch (sizeKey) {
      case 'small':
        return 'Small';
      case 'medium':
        return 'Medium';
      case 'large':
        return 'Large';
      case 'extraLarge':
        return 'Extra Large';
      default:
        return sizeKey;
    }
  }
}
