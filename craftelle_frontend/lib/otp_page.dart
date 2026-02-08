import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_page.dart';

class OTPVerificationPage extends StatefulWidget {
  final String email;

  const OTPVerificationPage({Key? key, required this.email}) : super(key: key);

  @override
  _OTPVerificationPageState createState() => _OTPVerificationPageState();
}

class _OTPVerificationPageState extends State<OTPVerificationPage> {
  List<TextEditingController> _otpControllers = List.generate(6, (index) => TextEditingController());
  List<FocusNode> _otpFocusNodes = List.generate(6, (index) => FocusNode());
  bool _isLoading = false;

  String get _otp => _otpControllers.map((controller) => controller.text).join('');

  Future<void> verifyOTP() async {
    if (_otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid 6-digit OTP')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse('https://neurosense-palsy.fly.dev/api/v1/users/verify-email/$_otp/${widget.email}');
    try {
      final response = await http.get(url);
      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['message'] == "Email verified successfully. You can log in now.") {
        showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Verification failed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred. Please try again.')),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  void showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Center(
            child: Text(
              "Email Verified Successfully",
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Color(0xFFFDA4AF), size: 80),
                const SizedBox(height: 16),
                const Text(
                  "Your email has been verified. Redirecting to login...",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15),
                ),
              ],
            ),
          ),
        );
      },
    );

    // Redirect to login page after 1 second
    Future.delayed(Duration(seconds: 1), () {
      Navigator.of(context).pop(); // Close dialog
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    });
  }

  Widget _buildOtpInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(6, (index) {
        return Container(
          width: 45,
          height: 55,
          decoration: BoxDecoration(
            border: Border.all(
              color: _otpFocusNodes[index].hasFocus ? Color(0xFFFDA4AF) : Colors.grey,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
            color: _otpFocusNodes[index].hasFocus
                ? Colors.grey.shade200
                : Colors.grey.shade100,
          ),
          child: TextFormField(
            controller: _otpControllers[index],
            focusNode: _otpFocusNodes[index],
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(1),
            ],
            decoration: InputDecoration(
              border: InputBorder.none,
              counterText: '',
            ),
            onChanged: (value) {
              if (value.isNotEmpty && index < 5) {
                FocusScope.of(context).requestFocus(_otpFocusNodes[index + 1]);
              } else if (value.isEmpty && index > 0) {
                FocusScope.of(context).requestFocus(_otpFocusNodes[index - 1]);
              }
              setState(() {}); // Refresh to update border colors
            },
          ),
        );
      }),
    );
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Verify Your Email"),
        backgroundColor: Color(0xFFFDA4AF),
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            SizedBox(height: 20),
            Text(
              "Enter the 6-digit OTP sent to ${widget.email}",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 30),

            _buildOtpInput(),
            SizedBox(height: 30),

            _isLoading
                ? CircularProgressIndicator(color: Color(0xFFFDA4AF))
                : ElevatedButton.icon(
                    onPressed: verifyOTP,
                    icon: Icon(Icons.verified, color: Colors.white),
                    label: Text("Verify Email", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                      textStyle: TextStyle(fontSize: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Color(0xFFFDA4AF),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
