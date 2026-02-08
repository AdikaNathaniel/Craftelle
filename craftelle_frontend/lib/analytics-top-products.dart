import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';

class AnalyticsTopProductsPage extends StatefulWidget {
  final String userEmail;
  const AnalyticsTopProductsPage({Key? key, required this.userEmail}) : super(key: key);

  @override
  _AnalyticsTopProductsPageState createState() => _AnalyticsTopProductsPageState();
}

class _AnalyticsTopProductsPageState extends State<AnalyticsTopProductsPage> {
  static const String _baseUrl = 'https://neurosense-palsy.fly.dev';
  bool _isLoading = true;
  String? _error;
  List<dynamic> _topProducts = [];
  List<dynamic> _categoryBreakdown = [];
  int _selectedDays = 30;

  final List<Color> _chartColors = [
    const Color(0xFFFDA4AF),
    const Color(0xFFF9A8D4),
    const Color(0xFFFDA4AF),
    const Color(0xFFFB7185),
    const Color(0xFFFB7185),
    const Color(0xFFFB7185),
    const Color(0xFFFDA4AF),
    const Color(0xFFFECDD3),
    const Color(0xFFFFE4E6),
    const Color(0xFFFECDD3),
  ];

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
        Uri.parse('$_baseUrl/api/v1/analytics/top-products?days=$_selectedDays&limit=10'),
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
            _topProducts = data['data']['topProducts'] ?? [];
            _categoryBreakdown = data['data']['categoryBreakdown'] ?? [];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF1F2),
      appBar: AppBar(
        title: const Text('Top Products', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFDA4AF),
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
                        const SizedBox(height: 20),
                        if (_topProducts.isNotEmpty) ...[
                          _buildSectionTitle('Most Ordered Products', Icons.trending_up_rounded),
                          const SizedBox(height: 12),
                          _buildBarChart(),
                          const SizedBox(height: 24),
                          _buildProductList(),
                        ],
                        if (_categoryBreakdown.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          _buildSectionTitle('Category Breakdown', Icons.pie_chart_rounded),
                          const SizedBox(height: 12),
                          _buildCategoryPieChart(),
                          const SizedBox(height: 12),
                          _buildCategoryLegend(),
                        ],
                        if (_topProducts.isEmpty && _categoryBreakdown.isEmpty)
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
            selectedColor: const Color(0xFFFDA4AF),
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

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFFDA4AF), size: 22),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildBarChart() {
    final maxVal = _topProducts.isNotEmpty
        ? _topProducts.map((p) => (p['totalOrdered'] as num).toDouble()).reduce((a, b) => a > b ? a : b)
        : 1.0;

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal * 1.2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final product = _topProducts[groupIndex];
                return BarTooltipItem(
                  '${product['productName']}\n${product['totalOrdered']} ordered',
                  const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < _topProducts.length) {
                    final name = _topProducts[idx]['productName'] as String;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        name.length > 6 ? '${name.substring(0, 6)}..' : name,
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: _topProducts.asMap().entries.map((entry) {
            final idx = entry.key;
            final product = entry.value;
            return BarChartGroupData(
              x: idx,
              barRods: [
                BarChartRodData(
                  toY: (product['totalOrdered'] as num).toDouble(),
                  color: _chartColors[idx % _chartColors.length],
                  width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildProductList() {
    return Column(
      children: _topProducts.asMap().entries.map((entry) {
        final idx = entry.key;
        final product = entry.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _chartColors[idx % _chartColors.length].withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '#${idx + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _chartColors[idx % _chartColors.length],
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product['productName'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(
                      product['category'] ?? 'General',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${product['totalOrdered']} sold',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFFDA4AF)),
                  ),
                  Text(
                    '\$${(product['totalRevenue'] ?? 0).toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryPieChart() {
    final total = _categoryBreakdown.fold<double>(0, (sum, c) => sum + (c['totalOrdered'] as num).toDouble());

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 50,
          sections: _categoryBreakdown.asMap().entries.map((entry) {
            final idx = entry.key;
            final cat = entry.value;
            final value = (cat['totalOrdered'] as num).toDouble();
            final pct = total > 0 ? (value / total * 100) : 0;
            return PieChartSectionData(
              color: _chartColors[idx % _chartColors.length],
              value: value,
              title: '${pct.toStringAsFixed(0)}%',
              titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
              radius: 55,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCategoryLegend() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: _categoryBreakdown.asMap().entries.map((entry) {
        final idx = entry.key;
        final cat = entry.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _chartColors[idx % _chartColors.length],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${cat['category']} (${cat['totalOrdered']})',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No product data available', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
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
              backgroundColor: const Color(0xFFFDA4AF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
