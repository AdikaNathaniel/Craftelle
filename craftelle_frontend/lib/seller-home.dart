import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'product-upload.dart';
import 'collections-page.dart';
import 'login_page.dart';
import 'chat-contacts.dart';
import 'seller-orders-page.dart';
import 'profile-page.dart';
import 'settings-page.dart';
import 'support-page.dart';

class SellerHomePage extends StatefulWidget {
  final String userEmail;

  const SellerHomePage({super.key, required this.userEmail});

  @override
  _SellerHomePageState createState() => _SellerHomePageState();
}

class _SellerHomePageState extends State<SellerHomePage> {
  int _currentIndex = 0;

  static const _pink = Color(0xFFFDA4AF);
  static const _pinkDark = Color(0xFFFB7185);

  final _pageTitles = ['Upload Product', 'Masterpieces', 'Orders', 'Messages'];

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
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar
              CircleAvatar(
                backgroundColor: _pink,
                radius: 40,
                child: Text(
                  widget.userEmail.isNotEmpty
                      ? widget.userEmail[0].toUpperCase()
                      : 'S',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      widget.userEmail,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Seller',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const Divider(height: 32),

              // My Profile
              ListTile(
                leading: const Icon(Icons.person_outline, color: _pink),
                title: const Text('My Profile'),
                onTap: () {
                  Navigator.pop(dialogContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ProfilePage(userEmail: widget.userEmail),
                    ),
                  );
                },
              ),
              // Settings
              ListTile(
                leading: const Icon(Icons.settings_outlined, color: _pink),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(dialogContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          SettingsPage(userEmail: widget.userEmail),
                    ),
                  );
                },
              ),

              // Support
              ListTile(
                leading: const Icon(Icons.support_agent, color: _pink),
                title: const Text('Support'),
                onTap: () {
                  Navigator.pop(dialogContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SupportPage(
                        userEmail: widget.userEmail,
                        userRole: 'Seller',
                      ),
                    ),
                  );
                },
              ),
              const Divider(height: 20),

              // Logout
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(dialogContext);
                  await _logout(context);
                },
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
      appBar: AppBar(
        title: Text(_pageTitles[_currentIndex]),
        centerTitle: true,
        backgroundColor: _pink,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              child: Text(
                widget.userEmail.isNotEmpty
                    ? widget.userEmail[0].toUpperCase()
                    : 'S',
                style: const TextStyle(color: _pink, fontSize: 16),
              ),
            ),
            onPressed: () {
              _showUserInfoDialog(context);
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: _pinkDark,
          unselectedItemColor: Colors.grey[400],
          selectedFontSize: 12,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.add_photo_alternate_outlined),
              activeIcon: Icon(Icons.add_photo_alternate),
              label: 'Upload',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.collections_outlined),
              activeIcon: Icon(Icons.collections),
              label: 'Masterpieces',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Orders',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_outlined),
              activeIcon: Icon(Icons.chat_rounded),
              label: 'Messages',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return ProductUploadPage(userEmail: widget.userEmail);
      case 1:
        return CollectionsPage(userEmail: widget.userEmail, isSellerView: true);
      case 2:
        return SellerOrdersPage(sellerEmail: widget.userEmail);
      case 3:
        return ChatContactsPage(
          userEmail: widget.userEmail,
          userName: widget.userEmail.split('@')[0],
          userRole: 'Seller',
        );
      default:
        return ProductUploadPage(userEmail: widget.userEmail);
    }
  }
}
