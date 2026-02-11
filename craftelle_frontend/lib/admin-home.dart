import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_page.dart';
import 'support-settings.dart';
import 'users_summary.dart';
import 'chat-contacts.dart';
import 'profile-page.dart';
import 'settings-page.dart';

class AdminHomePage extends StatefulWidget {
  final String userEmail;

  const AdminHomePage({super.key, required this.userEmail});

  @override
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _currentIndex = 0;

  static const _pink = Color(0xFFFDA4AF);
  static const _pinkDark = Color(0xFFFB7185);

  final _pageTitles = ['Users', 'Support', 'Messages'];

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
            (Route<dynamic> route) => false,
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
                      : 'A',
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
                'Admin',
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
                    : 'A',
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
              icon: Icon(Icons.supervised_user_circle_outlined),
              activeIcon: Icon(Icons.supervised_user_circle),
              label: 'Users',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.support_agent_outlined),
              activeIcon: Icon(Icons.support_agent),
              label: 'Support',
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
        return UserListPage(userEmail: widget.userEmail);
      case 1:
        return SupportSettingsPage(userEmail: widget.userEmail);
      case 2:
        return ChatContactsPage(
          userEmail: widget.userEmail,
          userName: widget.userEmail.split('@')[0],
          userRole: 'Admin',
        );
      default:
        return UserListPage(userEmail: widget.userEmail);
    }
  }
}

// Rest of the code remains the same (UserListPage, User, UserCard classes)...

// UserListPage with updated UI
class UserListPage extends StatefulWidget {
  final String userEmail;

  const UserListPage({Key? key, required this.userEmail}) : super(key: key);

  @override
  _UserListPageState createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  bool isLoading = true;
  List<User> users = [];

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    try {
      print('DEBUG: Fetching users from API...');
      final response = await http.get(
        Uri.parse('https://neurosense-palsy.fly.dev/api/v1/users'),
        headers: {'Content-Type': 'application/json'},
      );

      print('DEBUG: Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['success'] == true) {
          final List<dynamic> data = responseData['result'];
          print('DEBUG: Total users from API: ${data.length}');
          
          // Filter and parse only complete users
          List<User> completeUsers = [];
          
          for (var userData in data) {
            try {
              // Check if user has all required fields
              if (userData['name'] != null && 
                  userData['email'] != null && 
                  userData['type'] != null &&
                  userData['name'].toString().isNotEmpty &&
                  userData['email'].toString().isNotEmpty &&
                  userData['type'].toString().isNotEmpty) {
                
                final user = User.fromJson(userData);
                completeUsers.add(user);
              } else {
                print('DEBUG: Skipping incomplete user: ${userData['id']}');
              }
            } catch (e) {
              print('DEBUG: Error parsing user: $e');
            }
          }
          
          print('DEBUG: Complete users found: ${completeUsers.length}');
          
          setState(() {
            users = completeUsers;
            isLoading = false;
          });
        } else {
          print('DEBUG: API returned success: false');
          setState(() {
            isLoading = false;
          });
          _showSnackbar(
            context, 
            "Failed to load users: ${responseData['message']}", 
            Colors.red
          );
        }
      } else {
        print('DEBUG: HTTP error: ${response.statusCode}');
        setState(() {
          isLoading = false;
        });
        _showSnackbar(
          context, 
          "Server error: ${response.statusCode}", 
          Colors.red
        );
      }
    } catch (e) {
      print('DEBUG: Exception caught: $e');
      setState(() {
        isLoading = false;
      });
      _showSnackbar(
        context, 
        "Network error: ${e.toString()}", 
        Colors.red
      );
    }
  }

  void _showSnackbar(BuildContext context, String message, Color color) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: color,
      duration: const Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> _refreshData() async {
    setState(() {
      isLoading = true;
    });
    await fetchUsers();
  }

  Future<void> _deleteUser(String userId, String userName) async {
    try {
      final response = await http.delete(
        Uri.parse('https://neurosense-palsy.fly.dev/api/v1/users/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        _showSnackbar(context, "User '$userName' deleted successfully", const Color(0xFFFDA4AF));
        await _refreshData();
      } else {
        _showSnackbar(context, "Failed to delete user", Colors.red);
      }
    } catch (e) {
      _showSnackbar(context, "Error deleting user: ${e.toString()}", Colors.red);
    }
  }

  void _showDeleteUserDialog(User user) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Delete User',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Are you sure you want to delete this user?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person, size: 16, color: Color(0xFFFDA4AF)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            user.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.email, size: 16, color: Color(0xFFFDA4AF)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            user.email,
                            style: TextStyle(color: Colors.grey[700], fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.badge, size: 16, color: Color(0xFFFDA4AF)),
                        const SizedBox(width: 8),
                        Text(
                          user.type,
                          style: TextStyle(color: Colors.grey[700], fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'This action cannot be undone!',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                    ),
                    child: const Text("Cancel"),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteUser(user.id, user.name);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete, size: 18),
                        SizedBox(width: 6),
                        Text("Delete"),
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
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : users.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'No complete user profiles found',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Only users with name, email, and type are displayed',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _refreshData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFDA4AF),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    return UserCard(
                      user: users[index],
                      onTap: () => _showDeleteUserDialog(users[index]),
                    );
                  },
                ),
    );
  }
}

class User {
  final String id;
  final String name;
  final String email;
  final String type;
  final String? card;
  final bool isVerified;
  final bool isActive;
  final int failedLoginAttempts;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.type,
    this.card,
    required this.isVerified,
    required this.isActive,
    required this.failedLoginAttempts,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      card: json['card']?.toString(),
      isVerified: json['isVerified'] ?? false,
      isActive: json['isActive'] ?? false,
      failedLoginAttempts: json['failedLoginAttempts'] ?? 0,
    );
  }
}

class UserCard extends StatelessWidget {
  final User user;
  final VoidCallback onTap;

  const UserCard({Key? key, required this.user, required this.onTap}) : super(key: key);

  String _shortenName(String fullName) {
    final nameParts = fullName.trim().split(' ');
    if (nameParts.length <= 2) {
      return fullName; // Already short enough
    }
    // Return first name + last name
    return '${nameParts.first} ${nameParts.last}';
  }

  @override
  Widget build(BuildContext context) {
    // Determine icon, text and color based on user type
    IconData userTypeIcon;
    String userTypeText;
    Color userTypeColor;

    // Handle different user types with case-insensitive matching
    final typeLower = user.type.toLowerCase();
    
    if (typeLower.contains('admin')) {
      userTypeIcon = Icons.admin_panel_settings;
      userTypeText = 'Admin';
      userTypeColor = Colors.red;
    } else if (typeLower.contains('customer')) {
      userTypeIcon = Icons.person;
      userTypeText = 'Customer';
      userTypeColor = const Color(0xFFFDA4AF);
    } else if (typeLower.contains('seller')) {
      userTypeIcon = Icons.store;
      userTypeText = 'Seller';
      userTypeColor = const Color(0xFFFDA4AF);
    } else if (typeLower.contains('analyst')) {
      userTypeIcon = Icons.analytics;
      userTypeText = 'Analyst';
      userTypeColor = const Color(0xFFFB7185);
    } else {
      userTypeIcon = Icons.account_circle;
      userTypeText = user.type;
      userTypeColor = Colors.grey;
    }

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar/Icon with status indicator
            Stack(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: userTypeColor.withOpacity(0.15),
                  ),
                  child: Icon(
                    userTypeIcon,
                    color: userTypeColor,
                    size: 32,
                  ),
                ),
                // Active/Inactive indicator
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: user.isActive ? const Color(0xFFFDA4AF) : Colors.grey,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(width: 16),
            
            // User Information
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _shortenName(user.name),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Verification badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: user.isVerified ? const Color(0xFFFDA4AF).withOpacity(0.1) : const Color(0xFFFDA4AF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: user.isVerified ? const Color(0xFFFDA4AF) : const Color(0xFFFDA4AF),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              user.isVerified ? Icons.verified : Icons.pending,
                              size: 12,
                              color: user.isVerified ? const Color(0xFFFDA4AF) : const Color(0xFFFDA4AF),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              user.isVerified ? 'Verified' : 'Pending',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: user.isVerified ? const Color(0xFFFDA4AF) : const Color(0xFFFDA4AF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Email
                  Text(
                    user.email,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Type and card row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: userTypeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          userTypeText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: userTypeColor,
                          ),
                        ),
                      ),
                      
                      if (user.card != null && user.card!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Card: ${user.card}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                      
                      const Spacer(),
                      
                      // Failed login attempts indicator (if any)
                      if (user.failedLoginAttempts > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.warning_amber,
                                size: 12,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${user.failedLoginAttempts} fails',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}