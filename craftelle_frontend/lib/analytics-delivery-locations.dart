import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';

class AnalyticsDeliveryLocationsPage extends StatefulWidget {
  final String userEmail;
  const AnalyticsDeliveryLocationsPage({Key? key, required this.userEmail}) : super(key: key);

  @override
  _AnalyticsDeliveryLocationsPageState createState() => _AnalyticsDeliveryLocationsPageState();
}

class _AnalyticsDeliveryLocationsPageState extends State<AnalyticsDeliveryLocationsPage> {
  static const String _baseUrl = 'https://neurosense-palsy.fly.dev';
  bool _isLoading = true;
  String? _error;
  List<dynamic> _byCity = [];
  List<dynamic> _byRegion = [];
  int _totalOrders = 0;
  int _selectedDays = 30;
  bool _showCities = true;

  final List<Color> _chartColors = [
    const Color(0xFFFDA4AF),
    const Color(0xFFF9A8D4),
    const Color(0xFFFDA4AF),
    const Color(0xFFFB7185),
    const Color(0xFFFB7185),
    const Color(0xFFFB7185),
    const Color(0xFFFDA4AF),
    const Color(0xFFFECDD3),
    const Color(0xFFFECDD3),
    const Color(0xFFFFE4E6),
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
        Uri.parse('$_baseUrl/api/v1/analytics/delivery-locations?days=$_selectedDays&limit=10'),
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
            _byCity = data['data']['byCity'] ?? [];
            _byRegion = data['data']['byRegion'] ?? [];
            _totalOrders = data['data']['totalOrders'] ?? 0;
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
        title: const Text('Delivery Locations', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                        const SizedBox(height: 16),
                        _buildTotalOrdersBanner(),
                        const SizedBox(height: 20),
                        _buildToggle(),
                        const SizedBox(height: 16),
                        if (_currentData.isNotEmpty) ...[
                          _buildPieChart(),
                          const SizedBox(height: 20),
                          _buildLocationList(),
                        ] else
                          _buildEmptyState(),
                      ],
                    ),
                  ),
                ),
    );
  }

  List<dynamic> get _currentData => _showCities ? _byCity : _byRegion;
  String get _locationLabel => _showCities ? 'city' : 'region';

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

  Widget _buildTotalOrdersBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFDA4AF), Color(0xFFFDA4AF)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 32),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Total Deliveries', style: TextStyle(color: Colors.white70, fontSize: 13)),
              Text(
                '$_totalOrders orders',
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Spacer(),
          Text(
            '${_currentData.length}',
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 4),
          Text(
            _showCities ? 'cities' : 'regions',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _showCities = true),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: _showCities ? const Color(0xFFFDA4AF) : Colors.white,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                border: Border.all(color: const Color(0xFFFDA4AF)),
              ),
              child: Center(
                child: Text(
                  'By City',
                  style: TextStyle(
                    color: _showCities ? Colors.white : const Color(0xFFFDA4AF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _showCities = false),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: !_showCities ? const Color(0xFFFDA4AF) : Colors.white,
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
                border: Border.all(color: const Color(0xFFFDA4AF)),
              ),
              child: Center(
                child: Text(
                  'By Region',
                  style: TextStyle(
                    color: !_showCities ? Colors.white : const Color(0xFFFDA4AF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPieChart() {
    final total = _currentData.fold<double>(0, (sum, loc) => sum + (loc['orderCount'] as num).toDouble());

    return Container(
      height: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: _currentData.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final loc = entry.value;
                  final value = (loc['orderCount'] as num).toDouble();
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
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _currentData.asMap().entries.take(5).map((entry) {
                final idx = entry.key;
                final loc = entry.value;
                final name = loc[_locationLabel] ?? 'Unknown';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _chartColors[idx % _chartColors.length],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationList() {
    final maxCount = _currentData.isNotEmpty
        ? _currentData.map((d) => (d['orderCount'] as num).toDouble()).reduce((a, b) => a > b ? a : b)
        : 1.0;

    return Column(
      children: _currentData.asMap().entries.map((entry) {
        final idx = entry.key;
        final loc = entry.value;
        final name = loc[_locationLabel] ?? 'Unknown';
        final count = (loc['orderCount'] as num).toDouble();
        final revenue = loc['totalRevenue'] ?? 0;
        final pct = _totalOrders > 0 ? (count / _totalOrders * 100) : 0;
        final barPct = maxCount > 0 ? count / maxCount : 0.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _chartColors[idx % _chartColors.length].withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.location_on_rounded,
                      color: _chartColors[idx % _chartColors.length],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        Text(
                          '\$${revenue.toStringAsFixed(2)} revenue',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${count.toInt()} orders',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFFDA4AF)),
                      ),
                      Text(
                        '${pct.toStringAsFixed(1)}%',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: barPct,
                  backgroundColor: const Color(0xFFFFE4E6),
                  color: _chartColors[idx % _chartColors.length],
                  minHeight: 6,
                ),
              ),
            ],
          ),
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
            Icon(Icons.location_off_rounded, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No delivery location data available', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
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
