import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'analytics-top-products.dart';
import 'analytics-peak-times.dart';
import 'analytics-delivery-locations.dart';
import 'analytics-repeated-customers.dart';
import 'chat-contacts.dart';
import 'login_page.dart';

class AnalyticsHomePage extends StatefulWidget {
  final String userEmail;
  const AnalyticsHomePage({Key? key, required this.userEmail}) : super(key: key);

  @override
  _AnalyticsHomePageState createState() => _AnalyticsHomePageState();
}

class _AnalyticsHomePageState extends State<AnalyticsHomePage> {
  static const String _baseUrl = 'https://neurosense-palsy.fly.dev';
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic> _summary = {};
  int _selectedDays = 30;

  @override
  void initState() {
    super.initState();
    _fetchSummary();
  }

  Future<void> _fetchSummary() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/v1/analytics/summary?days=$_selectedDays'),
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
            _summary = data['data'] ?? {};
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = data['message'] ?? 'Failed to load summary';
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

  Future<void> _logout(BuildContext context) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/api/v1/users/logout'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success']) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => LoginPage()),
            (Route<dynamic> route) => false
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: ${e.toString()}')),
      );
    }
  }

  void _showUserInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Profile',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Email row
              Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.email_outlined, size: 20, color: Color(0xFFFDA4AF)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.userEmail,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Role row
              Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.badge_outlined, size: 20, color: Color(0xFFFDA4AF)),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Analyst',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFFDA4AF),
                    ),
                    child: const Text("Close"),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(dialogContext);
                      await _logout(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("Logout"),
                        SizedBox(width: 6),
                        Icon(Icons.logout, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF1F2), Color(0xFFFFFFFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            color: const Color(0xFFFDA4AF),
            onRefresh: _fetchSummary,
            child: CustomScrollView(
              slivers: [
                _buildAppBar(),
                SliverToBoxAdapter(child: _buildDaysSelector()),
                if (_isLoading)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFFFDA4AF)),
                    ),
                  )
                else if (_error != null)
                  SliverFillRemaining(child: _buildErrorWidget())
                else ...[
                  SliverToBoxAdapter(child: _buildSummaryCards()),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                      child: Text(
                        'Explore Analytics',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildNavCard(
                          'Top Products',
                          'Most ordered items & categories',
                          Icons.trending_up_rounded,
                          const Color(0xFFFDA4AF),
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AnalyticsTopProductsPage(
                                userEmail: widget.userEmail,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildNavCard(
                          'Peak Order Times',
                          'Busiest hours & days of the week',
                          Icons.schedule_rounded,
                          const Color(0xFFF9A8D4),
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AnalyticsPeakTimesPage(
                                userEmail: widget.userEmail,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildNavCard(
                          'Delivery Locations',
                          'Where orders are being delivered',
                          Icons.location_on_rounded,
                          const Color(0xFFFDA4AF),
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AnalyticsDeliveryLocationsPage(
                                userEmail: widget.userEmail,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildNavCard(
                          'Loyal Customers',
                          'Repeated buyers & VIP detection',
                          Icons.people_rounded,
                          const Color(0xFFFB7185),
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AnalyticsRepeatedCustomersPage(
                                userEmail: widget.userEmail,
                              ),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFFFDA4AF),
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Analytics Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFDA4AF), Color(0xFFF9A8D4), Color(0xFFFDA4AF)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
          child: const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 30),
              child: Icon(Icons.analytics_rounded, size: 48, color: Colors.white70),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.chat_rounded, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatContactsPage(
                  userEmail: widget.userEmail,
                  userName: widget.userEmail.split('@')[0],
                  userRole: 'Analyst',
                ),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: _fetchSummary,
        ),
        IconButton(
          icon: CircleAvatar(
            radius: 16,
            child: Text(
              widget.userEmail.isNotEmpty ? widget.userEmail[0].toUpperCase() : 'A',
              style: const TextStyle(color: Color(0xFFFDA4AF), fontSize: 16),
            ),
            backgroundColor: Colors.white,
          ),
          onPressed: () {
            _showUserInfoDialog(context);
          },
        ),
      ],
    );
  }

  Widget _buildDaysSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Text(
            'Time Range:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(width: 12),
          ...[7, 30, 90].map((days) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text('${days}d'),
              selected: _selectedDays == days,
              selectedColor: const Color(0xFFFDA4AF),
              labelStyle: TextStyle(
                color: _selectedDays == days ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedDays = days);
                  _fetchSummary();
                }
              },
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Orders',
                  '${_summary['totalOrders'] ?? 0}',
                  Icons.shopping_bag_rounded,
                  const Color(0xFFFDA4AF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Revenue',
                  '\$${(_summary['totalRevenue'] ?? 0).toStringAsFixed(2)}',
                  Icons.attach_money_rounded,
                  const Color(0xFFF9A8D4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Customers',
                  '${_summary['uniqueCustomers'] ?? 0}',
                  Icons.people_outline_rounded,
                  const Color(0xFFFDA4AF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Avg Order',
                  '\$${(_summary['avgOrderValue'] ?? 0).toStringAsFixed(2)}',
                  Icons.bar_chart_rounded,
                  const Color(0xFFFB7185),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: color.withOpacity(0.15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey.shade400, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchSummary,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFDA4AF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
