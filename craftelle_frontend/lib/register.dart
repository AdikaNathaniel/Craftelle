import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'otp_page.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _selectedUserType = 'Customer';

  static const String _baseUrl = 'https://neurosense-palsy.fly.dev';

  final List<String> _userTypes = [
    'Admin',
    'Customer',
    'Seller',
    'Analyst',
  ];

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  String _sanitizeInput(String input) {
    return input.trim();
  }

  String _extractErrorMessage(dynamic responseData) {
    if (responseData == null) {
      return "Registration failed";
    }

    var message = responseData['message'];

    if (message == null) {
      return "Registration failed";
    }

    if (message is String) {
      return message;
    }

    if (message is List) {
      return message.isNotEmpty ? message[0].toString() : "Registration failed";
    }

    return message.toString();
  }

  Future<void> _register(String name, String email, String password, String type,
                        String username, String phone) async {
    name = _sanitizeInput(name);
    email = _sanitizeInput(email.toLowerCase());
    password = _sanitizeInput(password);
    type = _sanitizeInput(type);
    username = _sanitizeInput(username);
    phone = _sanitizeInput(phone);

    // Validation for required fields
    if (name.isEmpty || email.isEmpty || password.isEmpty || type.isEmpty ||
        username.isEmpty || phone.isEmpty) {
      _showError("All fields are required!");
      return;
    }

    if (!_isValidEmail(email)) {
      _showError("Please enter a valid email address!");
      return;
    }

    if (password.length < 6) {
      _showError("Password must be at least 6 characters!");
      return;
    }

    List<String> validTypes = ['Admin', 'Customer', 'Seller', 'Analyst'];
    if (!validTypes.contains(type)) {
      _showError("Please select a valid user type");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final requestBody = {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'type': type,
        'username': username,
      };

      final response = await http.post(
        Uri.parse('${_baseUrl}/api/v1/users'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 15));

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        if (responseData['success'] == true) {
          _showSuccess("Registration Successful", email);
        } else {
          _showError(_extractErrorMessage(responseData));
        }
      } else {
        _showError(_extractErrorMessage(responseData));
      }
    } on FormatException {
      _showError("Invalid data format");
    } on http.ClientException catch (e) {
      _showError("Failed to connect: ${e.message}");
    } on TimeoutException {
      _showError("Request timed out");
    } catch (e) {
      _showError("An error occurred: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccess(String message, String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: Color(0xFFFDA4AF),
                size: 80,
              ),
              const SizedBox(height: 20),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                "Your account has been created successfully!",
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFDA4AF),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OTPVerificationPage(email: email),
                      ),
                    );
                  },
                  child: const Text(
                    "Continue",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFDA4AF), Color(0xFFF9A8D4), Color(0xFFFDA4AF)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFFECDD3), width: 3),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/craftelle.png',
                        fit: BoxFit.cover,
                        width: 150,
                        height: 150,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 60, color: Color(0xFFFDA4AF)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  _inputField("Full Name", _nameController, Icons.person),
                  const SizedBox(height: 15),
                  _inputField("Email", _emailController, Icons.email),
                  const SizedBox(height: 15),
                  _inputField("Username", _usernameController, Icons.person_outline),
                  const SizedBox(height: 15),
                  _inputField("Phone Number", _phoneController, Icons.phone, keyboardType: TextInputType.phone),
                  const SizedBox(height: 15),
                  _passwordField(),
                  const SizedBox(height: 15),
                  _userTypeDropdown(),
                  const SizedBox(height: 15),
                  const SizedBox(height: 20),
                  const SizedBox(height: 30),
                  _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : _registerButton(),
                  const SizedBox(height: 20),
                  _loginText(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField(String label, TextEditingController controller, IconData icon, 
                    {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.white),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
      ),
    );
  }

  Widget _passwordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: "Password",
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: const Icon(Icons.lock, color: Colors.white70),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: Colors.white70,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.white),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
      ),
    );
  }

  Widget _userTypeDropdown() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white),
        color: Colors.white.withOpacity(0.1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedUserType,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
            iconSize: 24,
            elevation: 16,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            dropdownColor: const Color(0xFFFDA4AF),
            isExpanded: true,
            onChanged: (String? newValue) {
              setState(() {
                _selectedUserType = newValue!;
              });
            },
            items: _userTypes.map<DropdownMenuItem<String>>((String value) {
              // Format display name for better readability
              String displayName = _formatUserTypeName(value);
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  displayName,
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  String _formatUserTypeName(String userType) {
    switch (userType) {
      case 'Admin':
        return 'Admin';
      case 'Customer':
        return 'Customer';
      case 'Seller':
        return 'Seller';
      case 'Analyst':
        return 'Analyst';
      default:
        return userType;
    }
  }

  Widget _registerButton() {
    return ElevatedButton(
      onPressed: () {
        // Validate all required fields
        if (_nameController.text.isEmpty ||
            _emailController.text.isEmpty ||
            _passwordController.text.isEmpty ||
            _usernameController.text.isEmpty ||
            _phoneController.text.isEmpty) {
          _showError("Please fill in all fields!");
          return;
        }

        _register(
          _nameController.text,
          _emailController.text,
          _passwordController.text,
          _selectedUserType,
          _usernameController.text,
          _phoneController.text,
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFFDA4AF),
        padding: const EdgeInsets.symmetric(vertical: 16),
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      child: const Text(
        "Register",
        style: TextStyle(fontSize: 20),
      ),
    );
  }

  Widget _loginText() {
    return GestureDetector(
      onTap: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      ),
      child: const Text(
        "Already have an account? Login",
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}