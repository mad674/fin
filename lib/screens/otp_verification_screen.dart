import 'package:flutter/material.dart';
import 'create_password_screen.dart';
import 'update_password_screen.dart';
import '../services/auth_service.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String email;
  final bool isForForgotPassword;
  final bool isEmailOTP;

  const OtpVerificationScreen({
    Key? key,
    required this.phoneNumber,
    required this.email,
    required this.isForForgotPassword,
    required this.isEmailOTP,
  }) : super(key: key);

  @override
  _OtpVerificationScreenState createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;

  Future<void> _verifyOtp() async {
    String otpInput = _otpController.text.trim();
    if (otpInput.length != 6) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Enter a valid 6-digit OTP")));
      return;
    }
    setState(() {
      _isLoading = true;
    });
    bool isVerified = false;
    try {
      if (widget.isEmailOTP) {
        isVerified = await AuthService.verifyEmailOTP(widget.email, otpInput);
      } else {
        isVerified = await AuthService.verifyPhoneOTP(widget.phoneNumber, otpInput);
      }
      if (isVerified) {
        if (widget.isForForgotPassword) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => UpdatePasswordScreen(phone: widget.phoneNumber),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CreatePasswordScreen(
                phone: widget.phoneNumber,
                email: widget.email,
                phoneVerified: widget.isEmailOTP ? false : true,
                emailVerified: widget.isEmailOTP ? true : false,
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Invalid OTP")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    String destination = widget.isEmailOTP ? widget.email : widget.phoneNumber;

    return Scaffold(
      body: Stack(
        children: [
          // Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)], // Blue gradient
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Content
          SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: screenHeight * 0.1), // Top spacing
                const Text(
                  "Verify OTP",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  "Enter the OTP sent to $destination",
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: screenHeight * 0.05), // Spacing below heading
                // OTP Input Field
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: "OTP",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    prefixIcon: const Icon(Icons.lock),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                // Verify Button
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _verifyOtp,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          backgroundColor: Colors.blueAccent,
                        ),
                        child: const Text(
                          "Verify OTP",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                const SizedBox(height: 16),
                // Resend OTP Link
                TextButton(
                  onPressed: () async {
                    setState(() => _isLoading = true);
                    try {
                      if (widget.isEmailOTP) {
                        await AuthService.sendEmailOTP(widget.email);
                      } else {
                        await AuthService.sendOTP(widget.phoneNumber);
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("OTP resent successfully")),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error: ${e.toString()}")),
                      );
                    } finally {
                      setState(() => _isLoading = false);
                    }
                  },
                  child: const Text(
                    "Resend OTP",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
