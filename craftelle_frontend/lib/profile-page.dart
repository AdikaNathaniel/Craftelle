import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProfilePage extends StatefulWidget {
  final String userEmail;

  const ProfilePage({Key? key, required this.userEmail}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const _pink = Color(0xFFFDA4AF);
  static const _pinkDark = Color(0xFFFB7185);
  static const _bg = Color(0xFFFFF1F2);
  static const _baseUrl = 'https://neurosense-palsy.fly.dev/api/v1/users';

  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;

  String _name = '';
  String _username = '';
  String _email = '';
  String _phone = '';
  String _type = '';

  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _usernameController = TextEditingController();
    _phoneController = TextEditingController();
    _fetchProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/profile/${widget.userEmail}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['result'] != null) {
          final user = data['result'];
          setState(() {
            _name = user['name'] ?? '';
            _username = user['username'] ?? '';
            _email = user['email'] ?? '';
            _phone = user['phone'] ?? '';
            _type = user['type'] ?? '';
            _nameController.text = _name;
            _usernameController.text = _username;
            _phoneController.text = _phone;
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load profile')),
      );
    }
  }

  Future<void> _saveProfile() async {
    final newName = _nameController.text.trim();
    final newUsername = _usernameController.text.trim();
    final newPhone = _phoneController.text.trim();

    if (newName.isEmpty || newUsername.isEmpty || newPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/update-profile'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': _email,
          'name': newName,
          'username': newUsername,
          'phone': newPhone,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['result'] != null) {
          final user = data['result'];
          setState(() {
            _name = user['name'] ?? newName;
            _username = user['username'] ?? newUsername;
            _phone = user['phone'] ?? newPhone;
            _isEditing = false;
            _isSaving = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 10),
                    Text('Profile updated successfully'),
                  ],
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                duration: const Duration(seconds: 2),
              ),
            );
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
    }

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile')),
      );
    }
  }

  void _toggleEdit() {
    if (_isEditing) {
      // Cancel editing — reset controllers
      _nameController.text = _name;
      _usernameController.text = _username;
      _phoneController.text = _phone;
    }
    setState(() => _isEditing = !_isEditing);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('My Profile'),
        centerTitle: true,
        backgroundColor: _pink,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_isLoading)
            IconButton(
              icon: Icon(_isEditing ? Icons.close : Icons.edit),
              onPressed: _toggleEdit,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _pink),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // Avatar
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: _pink,
                    child: Text(
                      _name.isNotEmpty
                          ? _name[0].toUpperCase()
                          : _email.isNotEmpty
                              ? _email[0].toUpperCase()
                              : '?',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: _pink.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _type,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _pinkDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Profile Fields Card
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
                        const Row(
                          children: [
                            Icon(Icons.person, color: _pinkDark, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Personal Information',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Full Name
                        _buildField(
                          icon: Icons.badge_outlined,
                          label: 'Full Name',
                          value: _name,
                          controller: _nameController,
                          editable: _isEditing,
                        ),
                        const SizedBox(height: 16),

                        // Username
                        _buildField(
                          icon: Icons.alternate_email,
                          label: 'Username',
                          value: _username,
                          controller: _usernameController,
                          editable: _isEditing,
                        ),
                        const SizedBox(height: 16),

                        // Email (read-only always)
                        _buildField(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: _email,
                          editable: false,
                        ),
                        const SizedBox(height: 16),

                        // Phone
                        _buildField(
                          icon: Icons.phone_outlined,
                          label: 'Phone Number',
                          value: _phone,
                          controller: _phoneController,
                          editable: _isEditing,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),

                        // Account Type (read-only always)
                        _buildField(
                          icon: Icons.shield_outlined,
                          label: 'Account Type',
                          value: _type,
                          editable: false,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Save Button
                  if (_isEditing)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _pink,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          minimumSize: const Size(double.infinity, 54),
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
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.save, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Save Changes',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildField({
    required IconData icon,
    required String label,
    required String value,
    TextEditingController? controller,
    bool editable = false,
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: editable ? Colors.white : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: editable ? _pink.withOpacity(0.5) : Colors.grey[200]!,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: editable ? _pinkDark : Colors.grey[400]),
              const SizedBox(width: 12),
              Expanded(
                child: editable && controller != null
                    ? TextField(
                        controller: controller,
                        keyboardType: keyboardType,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF1F2937),
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
              ),
              if (!editable)
                Icon(Icons.lock_outline, size: 16, color: Colors.grey[300]),
            ],
          ),
        ),
      ],
    );
  }
}
