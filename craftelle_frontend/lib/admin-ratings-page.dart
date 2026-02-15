import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminRatingsPage extends StatefulWidget {
  const AdminRatingsPage({Key? key}) : super(key: key);

  @override
  _AdminRatingsPageState createState() => _AdminRatingsPageState();
}

class _AdminRatingsPageState extends State<AdminRatingsPage> {
  static const _pink = Color(0xFFFDA4AF);
  static const _pinkDark = Color(0xFFFB7185);
  static const _ratingsUrl =
      'https://neurosense-palsy.fly.dev/api/v1/ratings';

  bool _isLoading = true;
  List<Map<String, dynamic>> _ratings = [];
  double _averageRating = 0.0;
  int _totalRatings = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);

    try {
      final responses = await Future.wait([
        http.get(
          Uri.parse('$_ratingsUrl/service/all'),
          headers: {'Content-Type': 'application/json'},
        ),
        http.get(
          Uri.parse('$_ratingsUrl/service/average'),
          headers: {'Content-Type': 'application/json'},
        ),
      ]);

      // All service ratings
      if (responses[0].statusCode == 200) {
        final data = json.decode(responses[0].body);
        if (data['success'] == true && data['result'] != null) {
          _ratings = List<Map<String, dynamic>>.from(data['result']);
        }
      }

      // Average
      if (responses[1].statusCode == 200) {
        final data = json.decode(responses[1].body);
        if (data['success'] == true && data['result'] != null) {
          _averageRating =
              (data['result']['averageRating'] ?? 0.0).toDouble();
          _totalRatings = data['result']['totalRatings'] ?? 0;
        }
      }
    } catch (e) {
      debugPrint('Error fetching ratings: $e');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y ago';
      if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
      return 'Just now';
    } catch (_) {
      return '';
    }
  }

  Widget _buildStars(int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < count ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 18,
          color: i < count ? _pinkDark : Colors.grey[300],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _pink));
    }

    return RefreshIndicator(
      onRefresh: _fetchData,
      color: _pink,
      child: _ratings.isEmpty
          ? ListView(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star_outline_rounded,
                            size: 72, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'No service ratings yet',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[500]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Customer ratings will appear here',
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _ratings.length + 1, // +1 for summary header
              itemBuilder: (context, index) {
                if (index == 0) return _buildSummaryCard();
                final rating = _ratings[index - 1];
                return _buildRatingCard(rating);
              },
            ),
    );
  }

  Widget _buildSummaryCard() {
    // Count ratings per star
    final starCounts = List.filled(6, 0); // index 0 unused, 1-5
    for (final r in _ratings) {
      final s = r['stars'] ?? 0;
      if (s >= 1 && s <= 5) starCounts[s]++;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          // Top row: average + total
          Row(
            children: [
              // Big average number
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _averageRating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Row(
                    children: List.generate(5, (i) {
                      return Icon(
                        i < _averageRating.round()
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 18,
                        color: Colors.white.withOpacity(
                            i < _averageRating.round() ? 1 : 0.4),
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_totalRatings ${_totalRatings == 1 ? 'rating' : 'ratings'}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              // Bar chart breakdown
              Expanded(
                child: Column(
                  children: List.generate(5, (i) {
                    final star = 5 - i;
                    final count = starCounts[star];
                    final pct =
                        _totalRatings > 0 ? count / _totalRatings : 0.0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Text(
                            '$star',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: pct,
                                backgroundColor:
                                    Colors.white.withOpacity(0.2),
                                color: Colors.white,
                                minHeight: 6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 24,
                            child: Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.85),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCard(Map<String, dynamic> rating) {
    final stars = rating['stars'] ?? 0;
    final email = rating['userEmail'] ?? 'Unknown';
    final feedback = rating['reviewText'] ?? '';
    final dateStr =
        rating['updatedAt'] ?? rating['createdAt'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _pink.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: avatar + email + time
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: _pink.withOpacity(0.15),
                child: Text(
                  email.isNotEmpty ? email[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: _pinkDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      email,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    _buildStars(stars),
                  ],
                ),
              ),
              Text(
                _timeAgo(dateStr),
                style: TextStyle(fontSize: 11, color: Colors.grey[400]),
              ),
            ],
          ),

          // Feedback text
          if (feedback.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                feedback,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
