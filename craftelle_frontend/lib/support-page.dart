import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SupportPage extends StatefulWidget {
  final String userEmail;
  final String userRole;

  const SupportPage({
    Key? key,
    required this.userEmail,
    required this.userRole,
  }) : super(key: key);

  @override
  _SupportPageState createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  static const _pink = Color(0xFFFDA4AF);
  static const _pinkDark = Color(0xFFFB7185);
  static const _bg = Color(0xFFFFF1F2);
  static const _baseUrl = 'https://neurosense-palsy.fly.dev/api/v1';

  final _messageController = TextEditingController();
  bool _isSending = false;
  bool _isLoadingProfile = true;

  String _userName = '';
  String _userPhone = '';

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/profile/${widget.userEmail}'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = data['result'];
        if (mounted) {
          setState(() {
            _userName = result['name'] ?? '';
            _userPhone = result['phone'] ?? '';
            _isLoadingProfile = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingProfile = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _submitRequest() async {
    final message = _messageController.text.trim();

    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe your issue')),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/support'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': _userName,
          'phoneNumber': _userPhone,
          'email': widget.userEmail,
          'message': message,
          'role': widget.userRole,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          _messageController.clear();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 10),
                  Text('Support request submitted!'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        throw Exception('Failed to submit');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit request. Try again.')),
        );
      }
    }

    if (mounted) setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Support'),
        centerTitle: true,
        backgroundColor: _pink,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoadingProfile
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _pink.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.support_agent,
                        color: _pinkDark, size: 48),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'How can we help?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Form Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _pink.withOpacity(0.2)),
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
                        // Email (read-only)
                        _buildReadOnlyField(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: widget.userEmail,
                        ),
                        const SizedBox(height: 16),

                        // Role (read-only)
                        _buildReadOnlyField(
                          icon: Icons.badge_outlined,
                          label: 'Role',
                          value: widget.userRole,
                        ),
                        const SizedBox(height: 16),

                        // Name (read-only, from profile)
                        _buildReadOnlyField(
                          icon: Icons.person_outline,
                          label: 'Name',
                          value: _userName,
                        ),
                        const SizedBox(height: 16),

                        // Phone (read-only, from profile)
                        _buildReadOnlyField(
                          icon: Icons.phone_outlined,
                          label: 'Phone Number',
                          value: _userPhone,
                        ),
                        const SizedBox(height: 16),

                        // Message
                        _buildInputField(
                          controller: _messageController,
                          icon: Icons.message_outlined,
                          label: 'Describe your issue',
                          maxLines: 4,
                        ),
                        const SizedBox(height: 24),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSending ? null : _submitRequest,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _pink,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              minimumSize: const Size(double.infinity, 54),
                            ),
                            child: _isSending
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.send, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Submit Request',
                                        style: TextStyle(
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
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildReadOnlyField({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Colors.grey[400]),
              const SizedBox(width: 12),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.lock_outline, size: 16, color: Colors.grey[300]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _pink.withOpacity(0.4)),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF1F2937),
            ),
            decoration: InputDecoration(
              prefixIcon: Padding(
                padding: EdgeInsets.only(
                    bottom: maxLines > 1 ? (maxLines - 1) * 20.0 : 0),
                child: Icon(icon, size: 20, color: _pinkDark),
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
