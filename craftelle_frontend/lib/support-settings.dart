import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';

class SupportSettingsPage extends StatefulWidget {
  final String userEmail;
  const SupportSettingsPage({super.key, required this.userEmail});

  @override
  State<SupportSettingsPage> createState() => _SupportSettingsPageState();
}

class _SupportSettingsPageState extends State<SupportSettingsPage> {
  static const _pink = Color(0xFFFDA4AF);
  static const _pinkDark = Color(0xFFFB7185);

  List<dynamic> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSupportRequests();
  }

  Future<void> _fetchSupportRequests() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('https://neurosense-palsy.fly.dev/api/v1/support'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _requests = data['result'] ?? [];
            _isLoading = false;
          });
        }
        return;
      }
    } catch (e) {
      debugPrint('Error fetching support requests: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year;
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$day/$month/$year at $hour:$minute';
    } catch (_) {
      return dateStr;
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('ID copied to clipboard'),
        backgroundColor: _pink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: _pink,
      onRefresh: _fetchSupportRequests,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _pink))
          : _requests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.support_agent, size: 60, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text(
                        'No support requests yet',
                        style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _requests.length,
                  itemBuilder: (context, index) {
                    return _buildRequestCard(_requests[index]);
                  },
                ),
    );
  }

  Widget _buildRequestCard(dynamic request) {
    final id = request['_id'] ?? '';
    final name = request['name'] ?? '';
    final role = request['role'] ?? '';
    final phone = request['phoneNumber'] ?? '';
    final email = request['email'] ?? '';
    final message = request['message'] ?? '';
    final createdAt = request['createdAt']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          // Header with ID and copy button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _pink.withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.vpn_key, color: _pinkDark, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    id,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () => _copyToClipboard(id),
                  child: const Icon(Icons.copy, size: 16, color: _pinkDark),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow(Icons.person, 'Name', name),
                if (role.isNotEmpty) _infoRow(Icons.badge, 'Role', role),
                _infoRow(Icons.phone, 'Phone', phone),
                _infoRow(Icons.email, 'Email', email),
                const SizedBox(height: 8),
                // Message section
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.message, color: _pink, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Message',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            message,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1F2937),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Date
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[400]),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(createdAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
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

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, color: _pink, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '$label: $value',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF374151),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
