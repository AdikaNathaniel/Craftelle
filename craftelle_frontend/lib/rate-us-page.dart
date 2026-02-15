import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'rating-widget.dart';

class RateUsPage extends StatefulWidget {
  final String userEmail;

  const RateUsPage({Key? key, required this.userEmail}) : super(key: key);

  @override
  _RateUsPageState createState() => _RateUsPageState();
}

class _RateUsPageState extends State<RateUsPage> {
  static const _pink = Color(0xFFFDA4AF);
  static const _pinkDark = Color(0xFFFB7185);
  static const _ratingsUrl = 'https://neurosense-palsy.fly.dev/api/v1/ratings';

  int _serviceRating = 0;
  bool _hasExistingServiceRating = false;
  bool _isLoading = true;
  bool _isSaving = false;
  final TextEditingController _feedbackController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchServiceRating();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _fetchServiceRating() async {
    try {
      final response = await http.get(
        Uri.parse('$_ratingsUrl/service/user/${widget.userEmail}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['result'] != null) {
          if (mounted) {
            setState(() {
              _serviceRating = data['result']['stars'] ?? 0;
              _feedbackController.text = data['result']['reviewText'] ?? '';
              _hasExistingServiceRating = true;
              _isLoading = false;
            });
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('Error fetching service rating: $e');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _submitServiceRating() async {
    if (_serviceRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a star rating')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final response = await http.post(
        Uri.parse(_ratingsUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'type': 'service',
          'userEmail': widget.userEmail,
          'stars': _serviceRating,
          'reviewText': _feedbackController.text.trim(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          if (mounted) {
            setState(() {
              _hasExistingServiceRating = true;
              _isSaving = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 10),
                    Text('Thank you for your feedback!'),
                  ],
                ),
                backgroundColor: _pinkDark,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('Error submitting service rating: $e');
    }

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit rating'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF1F2),
      appBar: AppBar(
        title: const Text('Rate Us'),
        centerTitle: true,
        backgroundColor: _pink,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _pink))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Header icon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_pink, _pinkDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _pinkDark.withOpacity(0.3),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.star_rounded, color: Colors.white, size: 44),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Rate Our Service',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'How would you rate your Craftelle experience?\nFrom ordering to delivery, let us know!',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500], height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),

                  // Rating card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _pink.withOpacity(0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Star rating
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: StarRating(
                            rating: _serviceRating,
                            onRatingChanged: (r) => setState(() => _serviceRating = r),
                            size: 44,
                          ),
                        ),

                        // Rating label
                        const SizedBox(height: 10),
                        Text(
                          _serviceRating == 0
                              ? 'Tap a star to rate'
                              : ['', 'Poor', 'Fair', 'Good', 'Great', 'Excellent'][_serviceRating],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _serviceRating == 0 ? Colors.grey[400] : _pinkDark,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Feedback field
                        TextField(
                          controller: _feedbackController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Share your feedback (optional)',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: _pink.withOpacity(0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: _pink, width: 2),
                            ),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Submit button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _submitServiceRating,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _pinkDark,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 2,
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _hasExistingServiceRating ? Icons.edit : Icons.send,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _hasExistingServiceRating ? 'Update Rating' : 'Submit Rating',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
