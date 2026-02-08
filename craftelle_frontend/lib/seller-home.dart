import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'product-upload.dart';
import 'collections-page.dart';
import 'login_page.dart';
import 'chat-contacts.dart';

class SellerHomePage extends StatefulWidget {
  final String userEmail;

  const SellerHomePage({super.key, required this.userEmail});

  @override
  _SellerHomePageState createState() => _SellerHomePageState();
}

class _SellerHomePageState extends State<SellerHomePage> {
  String _selectedPage = 'Upload Product';

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
    final isHomePage = _selectedPage == 'Upload Product';

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedPage),
        centerTitle: true,
        backgroundColor: const Color(0xFFFDA4AF),
        foregroundColor: Colors.white,
        leading: isHomePage
            ? Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _selectedPage = 'Upload Product';
                  });
                },
              ),
        actions: [
          IconButton(
            icon: CircleAvatar(
              radius: 16,
              child: Text(
                widget.userEmail.isNotEmpty ? widget.userEmail[0].toUpperCase() : 'S',
                style: const TextStyle(color: Color(0xFFFDA4AF), fontSize: 16),
              ),
              backgroundColor: Colors.white,
            ),
            onPressed: () {
              _showUserInfoDialog(context);
            },
          ),
        ],
      ),
      drawer: isHomePage ? Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              const DrawerHeader(
                decoration: BoxDecoration(
                  color: Color(0xFFFDA4AF),
                ),
                child: Center(
                  child: Text(
                    'SELLER',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.add_photo_alternate, color: Color(0xFFFDA4AF)),
                title: const Text('Upload Product'),
                selected: _selectedPage == 'Upload Product',
                onTap: () {
                  setState(() {
                    _selectedPage = 'Upload Product';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.collections, color: Color(0xFFFDA4AF)),
                title: const Text('Our Masterpieces'),
                selected: _selectedPage == 'Our Masterpieces',
                onTap: () {
                  setState(() {
                    _selectedPage = 'Our Masterpieces';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.chat_rounded, color: Color(0xFFFDA4AF)),
                title: const Text('Messages'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatContactsPage(
                        userEmail: widget.userEmail,
                        userName: widget.userEmail.split('@')[0],
                        userRole: 'Seller',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ) : null,
      body: _buildContent(_selectedPage),
    );
  }

  Widget _buildContent(String page) {
    switch (page) {
      case 'Upload Product':
        return ProductUploadPage(userEmail: widget.userEmail);
      case 'Our Masterpieces':
        return CollectionsPage(userEmail: widget.userEmail, isSellerView: true);
      default:
        return ProductUploadPage(userEmail: widget.userEmail);
    }
  }
}
