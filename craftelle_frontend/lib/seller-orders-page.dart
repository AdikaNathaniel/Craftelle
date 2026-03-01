import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'order-service.dart';
import 'order-pdf.dart';

class SellerOrdersPage extends StatefulWidget {
  final String sellerEmail;

  const SellerOrdersPage({Key? key, required this.sellerEmail})
      : super(key: key);

  @override
  _SellerOrdersPageState createState() => _SellerOrdersPageState();
}

class _SellerOrdersPageState extends State<SellerOrdersPage> {
  static const _pink = Color(0xFFFDA4AF);
  static const _pinkDark = Color(0xFFFB7185);
  static const _bg = Color(0xFFFFF1F2);

  List<Order> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final orders =
        await OrderService().fetchSellerOrders(widget.sellerEmail);
    if (mounted) {
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _pink),
      );
    }

    if (_orders.isEmpty) {
      return Container(
        color: _bg,
        child: Center(
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
                'Customer orders will appear here',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _isLoading = true);
                  _loadOrders();
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _pink,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: _bg,
      child: RefreshIndicator(
        onRefresh: _loadOrders,
        color: _pink,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          itemCount: _orders.length,
          itemBuilder: (context, index) =>
              _buildOrderCard(_orders[index], index),
        ),
      ),
    );
  }

  Widget _buildOrderCard(Order order, int index) {
    final dateStr =
        DateFormat('MMM d, yyyy - h:mm a').format(order.createdAt);
    final orderNum = _orders.length - index;

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
          // Header
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

          // Customer Info
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoChip(Icons.email_outlined, order.customerEmail),
                if (order.customerPhone.isNotEmpty)
                  _buildInfoChip(Icons.phone, order.customerPhone),
              ],
            ),
          ),

          // Delivery Location
          if (order.deliveryCity.isNotEmpty ||
              order.deliveryRegion.isNotEmpty ||
              order.deliveryAddress.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: _pinkDark),
                        const SizedBox(width: 6),
                        const Text(
                          'Delivery Location',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      [
                        if (order.deliveryAddress.isNotEmpty)
                          order.deliveryAddress,
                        if (order.deliveryCity.isNotEmpty) order.deliveryCity,
                        if (order.deliveryRegion.isNotEmpty)
                          order.deliveryRegion,
                      ].join(', '),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF4B5563),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Items
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
                  ...order.items.map((item) => _buildItemRow(item)),
                ],
              ),
            ),

          // Wish List / Extras
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
                            'Needs Pricing',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...order.wishListItems.map((item) => Padding(
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
                      )),
                ],
              ),
            ),

          // Order Status + Accept/Reject + PDF
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              children: [
                // Order Status Badge
                _buildStatusBadge(order.orderStatus),
                const Spacer(),
                // Payment Status
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: order.paymentStatus == 'Confirmed'
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        order.paymentStatus == 'Confirmed'
                            ? Icons.check_circle
                            : Icons.schedule,
                        size: 14,
                        color: order.paymentStatus == 'Confirmed'
                            ? Colors.green
                            : Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        order.paymentStatus,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: order.paymentStatus == 'Confirmed'
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Quote-aware Action Buttons + Download PDF
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                // Send Quote button (for pending quote orders)
                if (order.quoteStatus == 'pending')
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showPriceExtrasDialog(order, index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [_pink, _pinkDark]),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.request_quote, color: Colors.white, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Send Quote',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                // Awaiting Payment badge (for quoted orders)
                if (order.quoteStatus == 'quoted')
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.hourglass_top, color: Colors.blue, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Awaiting Payment',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Normal Accept/Reject (for non-quote orders or paid quote orders)
                if (order.quoteStatus == 'none' || order.quoteStatus == 'paid') ...[
                  if (order.orderStatus != 'Accepted')
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _updateStatus(order, index, 'Accepted'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                              SizedBox(width: 6),
                              Text('Accept', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (order.orderStatus != 'Accepted' && order.orderStatus != 'Rejected')
                    const SizedBox(width: 8),
                  if (order.orderStatus != 'Rejected')
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _updateStatus(order, index, 'Rejected'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cancel_outlined, color: Colors.red, size: 18),
                              SizedBox(width: 6),
                              Text('Reject', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
                const SizedBox(width: 8),
                // Download PDF Button
                GestureDetector(
                  onTap: () => OrderPdfGenerator.generateAndOpen(order, orderNum),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_pink, _pinkDark]),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(color: _pink.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.picture_as_pdf, color: Colors.white, size: 18),
                        SizedBox(width: 6),
                        Text('PDF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
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

  void _showPriceExtrasDialog(Order order, int index) {
    final controllers = order.wishListItems
        .map((_) => TextEditingController())
        .toList();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _pink.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.request_quote, color: _pinkDark, size: 32),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Price Extras',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                ),
                const SizedBox(height: 6),
                Text(
                  'Enter a price (GHS) for each extra item',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const SizedBox(height: 18),
                ...List.generate(order.wishListItems.length, (i) {
                  final item = order.wishListItems[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.text,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                        ),
                        if (item.specifications.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(item.specifications, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                          ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: controllers[i],
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            hintText: 'Price in GHS',
                            prefixText: 'GHS ',
                            prefixStyle: const TextStyle(color: _pinkDark, fontWeight: FontWeight.bold),
                            filled: true,
                            fillColor: _bg,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _pink.withOpacity(0.3))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _pink.withOpacity(0.3))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _pink, width: 2)),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text('Cancel', style: TextStyle(color: Colors.grey[600], fontSize: 15)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          // Validate all fields have a price
                          final quotedItems = <Map<String, dynamic>>[];
                          for (int i = 0; i < order.wishListItems.length; i++) {
                            final priceText = controllers[i].text.trim();
                            final price = double.tryParse(priceText);
                            if (price == null || price <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Please enter a valid price for "${order.wishListItems[i].text}"'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            quotedItems.add({
                              'text': order.wishListItems[i].text,
                              'specifications': order.wishListItems[i].specifications,
                              'quotedPrice': price,
                            });
                          }

                          Navigator.pop(ctx);
                          setState(() => _isLoading = true);

                          final success = await OrderService().submitQuote(order.id, quotedItems);
                          if (success && mounted) {
                            _loadOrders();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.white),
                                    SizedBox(width: 10),
                                    Text('Quote sent! Customer will be notified.'),
                                  ],
                                ),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          } else if (mounted) {
                            setState(() => _isLoading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Failed to submit quote')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _pinkDark,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Send Quote', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _updateStatus(Order order, int index, String status) async {
    final success = await OrderService().updateOrderStatus(order.id, status);
    if (success && mounted) {
      setState(() => _isLoading = true);
      _loadOrders();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                status == 'Accepted' ? Icons.check_circle : Icons.cancel,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Text('Order $status'),
            ],
          ),
          backgroundColor: status == 'Accepted' ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update order status')),
      );
    }
  }

  Widget _buildStatusBadge(String status) {
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

  Widget _buildInfoChip(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _pinkDark),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF4B5563),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
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

  Widget _buildItemRow(OrderItem item) {
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
                  child: Icon(Icons.image,
                      color: _pink.withOpacity(0.4), size: 20),
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
                if (item.selectedSize != null && item.displaySize.isNotEmpty)
                  Text(
                    item.displaySize,
                    style: const TextStyle(
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
}
