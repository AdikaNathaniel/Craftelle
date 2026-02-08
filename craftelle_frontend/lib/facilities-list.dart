import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'chat-contacts.dart';
import 'login_page.dart';

class FacilitiesListPage extends StatefulWidget {
  final String? userEmail;
  final String? userType;

  const FacilitiesListPage({Key? key, this.userEmail, this.userType}) : super(key: key);

  @override
  _FacilitiesListPageState createState() => _FacilitiesListPageState();
}

class _FacilitiesListPageState extends State<FacilitiesListPage> {
  List<dynamic> facilities = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchFacilities();
  }

  Future<void> _fetchFacilities() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('https://neurosense-palsy.fly.dev/api/v1/facilities'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            facilities = data['result']['facilities'];
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = 'Failed to load facilities: ${data['message']}';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Failed to load facilities: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching facilities: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    try {
      final response = await http.put(
        Uri.parse('https://neurosense-palsy.fly.dev/api/v1/users/logout'),
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
                        widget.userEmail ?? 'No email',
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
                    Expanded(
                      child: Text(
                        widget.userType ?? 'User',
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

  Future<void> _launchURL(String url) async {
    if (url.isEmpty || url == 'No Email' || url == 'No Phone' || url == 'No Website') return;
    
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }

  Future<void> _launchEmail(String email) async {
    if (email.isEmpty || email == 'No Email') return;
    
    final Uri uri = Uri.parse('mailto:$email');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch email')),
      );
    }
  }

  Future<void> _launchPhone(String phone) async {
    if (phone.isEmpty || phone == 'No Phone') return;
    
    final Uri uri = Uri.parse('tel:$phone');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch phone')),
      );
    }
  }

  Widget _buildFacilityCard(Map<String, dynamic> facility) {
    final location = facility['location'] ?? {};
    final year = facility['establishedYear']?.toString() ?? 'Not specified';
    
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Color(0xFFFFE4E6),
                  backgroundImage: facility['image'] != null && 
                                    facility['image'].toString().isNotEmpty
                      ? NetworkImage(facility['image'].toString())
                      : null,
                  child: facility['image'] == null || facility['image'].toString().isEmpty
                      ? Icon(Icons.business, size: 40, color: Color(0xFFFDA4AF))
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        facility['facilityName'] ?? 'No Name',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFDA4AF),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Clickable Email
            _buildClickableInfoRow(
              Icons.email, 
              facility['email'] ?? 'No Email',
              onTap: () => _launchEmail(facility['email'] ?? ''),
            ),
            
            // Clickable Phone
            _buildClickableInfoRow(
              Icons.phone, 
              facility['phoneNumber'] ?? 'No Phone',
              onTap: () => _launchPhone(facility['phoneNumber'] ?? ''),
            ),
            
            _buildInfoRow(Icons.calendar_today, 'Established: $year'),
            
            // Clickable Website
            _buildClickableInfoRow(
              Icons.language, 
              facility['website'] ?? 'No Website',
              onTap: () => _launchURL(facility['website'] ?? ''),
            ),
            
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Location Details:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            _buildLocationRow(Icons.location_on, location['address'] ?? 'No Address'),
            _buildLocationRow(Icons.location_city, location['city'] ?? 'No City'),
            _buildLocationRow(Icons.map, location['state'] ?? 'No State'),
            _buildLocationRow(Icons.public, location['country'] ?? 'No Country'),
            
            if (facility['description'] != null && facility['description'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Description:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                facility['description'].toString(),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Color(0xFFFDA4AF)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClickableInfoRow(IconData icon, String text, {VoidCallback? onTap}) {
    final isClickable = onTap != null && text != 'No Email' && text != 'No Phone' && text != 'No Website';
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: isClickable ? onTap : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: Color(0xFFFDA4AF)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  color: isClickable ? Colors.blue : Colors.black,
                  decoration: isClickable ? TextDecoration.underline : null,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Facilities Directory'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xFFFDA4AF),
        foregroundColor: Colors.white,
        actions: [
          if (widget.userEmail != null)
            IconButton(
              icon: const Icon(Icons.chat_rounded),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatContactsPage(
                      userEmail: widget.userEmail!,
                      userName: widget.userEmail!.split('@')[0],
                      userRole: widget.userType ?? 'Customer',
                    ),
                  ),
                );
              },
              tooltip: 'Messages',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchFacilities,
            tooltip: 'Refresh',
          ),
          if (widget.userEmail != null)
            IconButton(
              icon: CircleAvatar(
                radius: 16,
                child: Text(
                  widget.userEmail!.isNotEmpty ? widget.userEmail![0].toUpperCase() : 'U',
                  style: const TextStyle(color: Color(0xFFFDA4AF), fontSize: 16),
                ),
                backgroundColor: Colors.white,
              ),
              onPressed: () {
                _showUserInfoDialog(context);
              },
              tooltip: 'Profile',
            ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFDA4AF)),
              ),
            )
          : errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          errorMessage,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _fetchFacilities,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFFDA4AF),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : facilities.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.business_outlined,
                            size: 64,
                            color: Color(0xFFFDA4AF),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No facilities found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add facilities to see them here',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _fetchFacilities,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFFDA4AF),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchFacilities,
                      color: Color(0xFFFDA4AF),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            color: Color(0xFFFFF1F2),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Facilities: ${facilities.length}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFFFDA4AF),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFFDA4AF).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.business, size: 14, color: Color(0xFFFDA4AF)),
                                      const SizedBox(width: 6),
                                      Text(
                                        'All Facilities',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFFFDA4AF),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          Expanded(
                            child: ListView.builder(
                              itemCount: facilities.length,
                              itemBuilder: (context, index) {
                                return _buildFacilityCard(facilities[index]);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}