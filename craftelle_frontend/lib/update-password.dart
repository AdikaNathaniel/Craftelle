import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'craftelle-dialog.dart';

class UpdatePasswordPage extends StatefulWidget {
  const UpdatePasswordPage({super.key});

  @override
  State<UpdatePasswordPage> createState() => _UpdatePasswordPageState();
}

class _UpdatePasswordPageState extends State<UpdatePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  bool _isLoading = false;

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.patch(
        Uri.parse('https://neurosense-palsy.fly.dev/api/v1/users/update-password-or-name'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "email": _emailController.text.trim(),
          "oldPassword": _oldPasswordController.text.trim(),
          "newPassword": _newPasswordController.text.trim(),
        }),
      ).timeout(const Duration(seconds: 10));

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        // Clear all text fields
        _emailController.clear();
        _oldPasswordController.clear();
        _newPasswordController.clear();

        if (mounted) {
          CraftelleDialog.showSuccess(
            context,
            title: 'Password Updated',
            message: 'Your password has been successfully updated.',
          );
        }
      } else {
        final errorMsg = json.decode(response.body)['message'] ?? 'Server error';
        if (mounted) {
          CraftelleDialog.showError(
            context,
            title: 'Update Failed',
            message: errorMsg is List ? errorMsg[0].toString() : errorMsg.toString(),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        CraftelleDialog.showError(
          context,
          title: 'Network Error',
          message: 'Failed to connect to the server. Please check your internet connection.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Password'),
        centerTitle: true,
        backgroundColor: Color(0xFFFB7185),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildTextField(_emailController, 'Email', Icons.email),
              const SizedBox(height: 20),
              _buildTextField(_oldPasswordController, 'Old Password', Icons.lock, obscure: true),
              const SizedBox(height: 20),
              _buildTextField(_newPasswordController, 'New Password', Icons.lock_outline, obscure: true),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updatePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFB7185),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Update Password',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon,
      {bool obscure = false}) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: (value) =>
          (value == null || value.trim().isEmpty) ? 'Please enter $label' : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }
}