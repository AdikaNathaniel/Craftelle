import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';

class AnalyticsPeakTimesPage extends StatefulWidget {
  final String userEmail;
  const AnalyticsPeakTimesPage({Key? key, required this.userEmail}) : super(key: key);

  @override
  _AnalyticsPeakTimesPageState createState() => _AnalyticsPeakTimesPageState();
}

class _AnalyticsPeakTimesPageState extends State<AnalyticsPeakTimesPage> {
  static const String _baseUrl = 'https://neurosense-palsy.fly.dev';
  bool _isLoading = true;
  String? _error;
  List<dynamic> _byHour = [];
  List<dynamic> _byDayOfWeek = [];
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
        Uri.parse('$_baseUrl/api/v1/analytics/peak-times?days=$_selectedDays'),
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
            _byHour = data['data']['byHour'] ?? [];
            _byDayOfWeek = data['data']['byDayOfWeek'] ?? [];
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
        title: const Text('Peak Order Times', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF9A8D4),
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
                        if (_byHour.isNotEmpty) ...[
                          _buildSectionTitle('Orders by Hour of Day', Icons.access_time_rounded),
                          const SizedBox(height: 8),
                          _buildPeakHourHighlight(),
                          const SizedBox(height: 12),
                          _buildHourlyChart(),
                        ],
                        if (_byDayOfWeek.isNotEmpty) ...[
                          const SizedBox(height: 28),
                          _buildSectionTitle('Orders by Day of Week', Icons.calendar_today_rounded),
                          const SizedBox(height: 8),
                          _buildPeakDayHighlight(),
                          const SizedBox(height: 12),
                          _buildDayOfWeekChart(),
                          const SizedBox(height: 16),
                          _buildDayOfWeekCards(),
                        ],
                        if (_byHour.isEmpty && _byDayOfWeek.isEmpty)
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
            selectedColor: const Color(0xFFF9A8D4),
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
        Icon(icon, color: const Color(0xFFF9A8D4), size: 22),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildPeakHourHighlight() {
    if (_byHour.isEmpty) return const SizedBox.shrink();
    final peak = _byHour.reduce((a, b) =>
        (a['orderCount'] as num) > (b['orderCount'] as num) ? a : b);
    final hour = peak['hour'] as int;
    final hourStr = hour == 0 ? '12 AM' : hour < 12 ? '$hour AM' : hour == 12 ? '12 PM' : '${hour - 12} PM';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF9A8D4), Color(0xFFFDA4AF)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Peak Hour', style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text(
                  '$hourStr — ${peak['orderCount']} orders',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeakDayHighlight() {
    if (_byDayOfWeek.isEmpty) return const SizedBox.shrink();
    final peak = _byDayOfWeek.reduce((a, b) =>
        (a['orderCount'] as num) > (b['orderCount'] as num) ? a : b);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFDA4AF), Color(0xFFFB7185)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.star_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Busiest Day', style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text(
                  '${peak['dayName']} — ${peak['orderCount']} orders',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyChart() {
    // Fill all 24 hours, defaulting to 0
    final Map<int, int> hourMap = {};
    for (final h in _byHour) {
      hourMap[h['hour'] as int] = h['orderCount'] as int;
    }

    final maxVal = hourMap.values.isNotEmpty
        ? hourMap.values.reduce((a, b) => a > b ? a : b).toDouble()
        : 1.0;

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
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
                final hour = group.x;
                final hourStr = hour == 0 ? '12 AM' : hour < 12 ? '$hour AM' : hour == 12 ? '12 PM' : '${hour - 12} PM';
                return BarTooltipItem(
                  '$hourStr\n${rod.toY.toInt()} orders',
                  const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 3,
                getTitlesWidget: (value, meta) {
                  final h = value.toInt();
                  if (h % 3 != 0) return const SizedBox.shrink();
                  final label = h == 0 ? '12a' : h < 12 ? '${h}a' : h == 12 ? '12p' : '${h - 12}p';
                  return Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600));
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 35,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(24, (hour) {
            final count = (hourMap[hour] ?? 0).toDouble();
            final intensity = maxVal > 0 ? count / maxVal : 0.0;
            return BarChartGroupData(
              x: hour,
              barRods: [
                BarChartRodData(
                  toY: count,
                  color: Color.lerp(const Color(0xFFFDA4AF), const Color(0xFFFDA4AF), intensity.toDouble()) ?? const Color(0xFFFDA4AF),
                  width: 8,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildDayOfWeekChart() {
    final maxVal = _byDayOfWeek.isNotEmpty
        ? _byDayOfWeek.map((d) => (d['orderCount'] as num).toDouble()).reduce((a, b) => a > b ? a : b)
        : 1.0;

    return Container(
      height: 200,
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
                if (groupIndex < _byDayOfWeek.length) {
                  final day = _byDayOfWeek[groupIndex];
                  return BarTooltipItem(
                    '${day['dayName']}\n${day['orderCount']} orders',
                    const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  );
                }
                return null;
              },
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < _byDayOfWeek.length) {
                    final name = (_byDayOfWeek[idx]['dayName'] as String);
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        name.substring(0, 3),
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
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
                reservedSize: 35,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          barGroups: _byDayOfWeek.asMap().entries.map((entry) {
            final idx = entry.key;
            final day = entry.value;
            final count = (day['orderCount'] as num).toDouble();
            final intensity = maxVal > 0 ? count / maxVal : 0.0;
            return BarChartGroupData(
              x: idx,
              barRods: [
                BarChartRodData(
                  toY: count,
                  color: Color.lerp(const Color(0xFFFB7185), const Color(0xFFFB7185), intensity.toDouble()) ?? const Color(0xFFFDA4AF),
                  width: 28,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDayOfWeekCards() {
    final maxCount = _byDayOfWeek.isNotEmpty
        ? _byDayOfWeek.map((d) => (d['orderCount'] as num).toDouble()).reduce((a, b) => a > b ? a : b)
        : 1.0;

    return Column(
      children: _byDayOfWeek.map((day) {
        final count = (day['orderCount'] as num).toDouble();
        final pct = maxCount > 0 ? count / maxCount : 0.0;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 50,
                child: Text(
                  (day['dayName'] as String).substring(0, 3),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: const Color(0xFFFFE4E6),
                    color: const Color(0xFFFDA4AF),
                    minHeight: 10,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${day['orderCount']}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFFDA4AF)),
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
            Icon(Icons.schedule_rounded, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No timing data available', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
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
              backgroundColor: const Color(0xFFF9A8D4),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}