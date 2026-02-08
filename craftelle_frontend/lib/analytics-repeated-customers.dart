import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class AnalyticsRepeatedCustomersPage extends StatefulWidget {
  final String userEmail;
  const AnalyticsRepeatedCustomersPage({Key? key, required this.userEmail}) : super(key: key);

  @override
  _AnalyticsRepeatedCustomersPageState createState() => _AnalyticsRepeatedCustomersPageState();
}

class _AnalyticsRepeatedCustomersPageState extends State<AnalyticsRepeatedCustomersPage> {
  static const String _baseUrl = 'https://neurosense-palsy.fly.dev';
  bool _isLoading = true;
  String? _error;
  List<dynamic> _customers = [];
  int _totalRepeatedCustomers = 0;
  int _selectedDays = 30;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/v1/analytics/repeated-customers?days=$_selectedDays&limit=20'),
        headers: {
          'Content-Type': 'application/json',
          'role': 'Analyst',
          'email': widget.userEmail,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _customers = data['data']['customers'] ?? [];
            _totalRepeatedCustomers = data['data']['totalRepeatedCustomers'] ?? 0;
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = data['message'] ?? 'Failed to load data';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Server error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Connection error: $e';
        _isLoading = false;
      });
    }
  }

  String _getBadge(int totalOrders) {
    if (totalOrders >= 10) return 'VIP';
    if (totalOrders >= 5) return 'Loyal';
    return 'Regular';
  }

  Color _getBadgeColor(int totalOrders) {
    if (totalOrders >= 10) return const Color(0xFFFECDD3);
    if (totalOrders >= 5) return const Color(0xFFFDA4AF);
    return const Color(0xFFFB7185);
  }

  IconData _getBadgeIcon(int totalOrders) {
    if (totalOrders >= 10) return Icons.diamond_rounded;
    if (totalOrders >= 5) return Icons.star_rounded;
    return Icons.favorite_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF1F2),
      appBar: AppBar(
        title: const Text('Loyal Customers', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFB7185),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFDA4AF)))
          : _error != null
              ? _buildErrorWidget()
              : RefreshIndicator(
                  color: const Color(0xFFFDA4AF),
                  onRefresh: _fetchData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDaysSelector(),
                        const SizedBox(height: 16),
                        _buildSummaryBanner(),
                        const SizedBox(height: 16),
                        _buildBadgeLegend(),
                        const SizedBox(height: 20),
                        if (_customers.isNotEmpty)
                          _buildCustomerList()
                        else
                          _buildEmptyState(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildDaysSelector() {
    return Row(
      children: [
        Text('Period:', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
        const SizedBox(width: 12),
        ...[7, 30, 90].map((days) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text('${days}d'),
            selected: _selectedDays == days,
            selectedColor: const Color(0xFFFB7185),
            labelStyle: TextStyle(
              color: _selectedDays == days ? Colors.white : Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
            onSelected: (selected) {
              if (selected) {
                setState(() => _selectedDays = days);
                _fetchData();
              }
            },
          ),
        )),
      ],
    );
  }

  Widget _buildSummaryBanner() {
    // Calculate summary stats
    final totalSpent = _customers.fold<double>(0, (sum, c) => sum + ((c['totalSpent'] ?? 0) as num).toDouble());
    final totalOrders = _customers.fold<int>(0, (sum, c) => sum + ((c['totalOrders'] ?? 0) as num).toInt());
    final vipCount = _customers.where((c) => (c['totalOrders'] as num).toInt() >= 10).length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFB7185), Color(0xFFFDA4AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.people_rounded, color: Colors.white, size: 28),
              const SizedBox(width: 10),
              const Text('Returning Customers', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildBannerStat('Customers', '$_totalRepeatedCustomers')),
              Container(width: 1, height: 36, color: Colors.white30),
              Expanded(child: _buildBannerStat('Total Orders', '$totalOrders')),
              Container(width: 1, height: 36, color: Colors.white30),
              Expanded(child: _buildBannerStat('Revenue', '\$${totalSpent.toStringAsFixed(0)}')),
              Container(width: 1, height: 36, color: Colors.white30),
              Expanded(child: _buildBannerStat('VIPs', '$vipCount')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBannerStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  Widget _buildBadgeLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('Regular', '2-4 orders', const Color(0xFFFB7185), Icons.favorite_rounded),
        const SizedBox(width: 16),
        _buildLegendItem('Loyal', '5-9 orders', const Color(0xFFFDA4AF), Icons.star_rounded),
        const SizedBox(width: 16),
        _buildLegendItem('VIP', '10+ orders', const Color(0xFFFECDD3), Icons.diamond_rounded),
      ],
    );
  }

  Widget _buildLegendItem(String label, String desc, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
              Text(desc, style: TextStyle(fontSize: 9, color: color.withOpacity(0.7))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerList() {
    return Column(
      children: _customers.asMap().entries.map((entry) {
        final idx = entry.key;
        final customer = entry.value;
        final totalOrders = (customer['totalOrders'] as num).toInt();
        final totalSpent = (customer['totalSpent'] ?? 0 as num).toDouble();
        final name = customer['name'] ?? 'Unknown';
        final email = customer['email'] ?? '';
        final uniqueProducts = customer['uniqueProducts'] ?? 0;
        final badge = _getBadge(totalOrders);
        final badgeColor = _getBadgeColor(totalOrders);
        final badgeIcon = _getBadgeIcon(totalOrders);

        String lastOrderStr = '';
        if (customer['lastOrderDate'] != null) {
          try {
            final date = DateTime.parse(customer['lastOrderDate']);
            lastOrderStr = DateFormat('MMM d, yyyy').format(date);
          } catch (_) {
            lastOrderStr = '';
          }
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                child: Row(
                  children: [
                    // Rank & Avatar
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: badgeColor.withOpacity(0.15),
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: badgeColor),
                          ),
                        ),
                        if (idx < 3)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDA4AF),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: Center(
                                child: Text(
                                  '${idx + 1}',
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    // Name & Email
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          if (email.isNotEmpty)
                            Text(email, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: badgeColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(badgeIcon, color: badgeColor, size: 14),
                          const SizedBox(width: 4),
                          Text(badge, style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Stats row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                ),
                child: Row(
                  children: [
                    _buildCustomerStat(Icons.shopping_bag_outlined, '$totalOrders orders', const Color(0xFFFDA4AF)),
                    const SizedBox(width: 16),
                    _buildCustomerStat(Icons.attach_money_rounded, '\$${totalSpent.toStringAsFixed(2)}', const Color(0xFFFB7185)),
                    const SizedBox(width: 16),
                    _buildCustomerStat(Icons.inventory_2_outlined, '$uniqueProducts products', const Color(0xFFFDA4AF)),
                    if (lastOrderStr.isNotEmpty) ...[
                      const Spacer(),
                      Text(lastOrderStr, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCustomerStat(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(Icons.people_outline_rounded, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No repeated customers found', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
            const SizedBox(height: 8),
            Text(
              'Customers with 2+ orders will appear here',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(_error!, style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _fetchData,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFB7185),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
