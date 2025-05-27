import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

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
          Column(
            children: [
              // Heading at the Top
              Padding(
                padding: EdgeInsets.only(top: screenHeight * 0.08), // 8% of screen height
                child: Column(
                  children: [
                    const Text(
                      "Finance GPT",
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 42, // Increased font size for heading
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.01), // Spacing below heading
                    const Text(
                      "Your AI-powered financial assistant",
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 18, // Tagline font size
                        fontWeight: FontWeight.w400,
                        color: Colors.white70, // Subtle color for tagline
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: screenHeight * 0.05), // Spacing below heading
              // Lottie Animation
              SizedBox(
                height: screenHeight * 0.45, // Increased to 45% of screen height
                width: screenWidth * 0.9, // Increased to 90% of screen width
                child: Lottie.asset(
                  'assets/animations/xyz.json', // Replace with your Lottie file
                  fit: BoxFit.contain,
                  repeat: true,
                ),
              ),
              SizedBox(height: screenHeight * 0.03), // Spacing below animation
              // Buttons
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1), // 10% horizontal padding
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Login Button
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LoginScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.1, // 10% of screen width
                          vertical: screenHeight * 0.02, // 2% of screen height
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30), // Rounded corners
                        ),
                        elevation: 8, // Shadow depth
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.login, color: Colors.white),
                          SizedBox(width: 10),
                          Text(
                            "Login",
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02), // Spacing between buttons
                    // Sign Up Button
                    OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => RegisterScreen()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.1, // 10% of screen width
                          vertical: screenHeight * 0.02, // 2% of screen height
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30), // Rounded corners
                        ),
                        side: const BorderSide(color: Colors.white, width: 2), // Border width
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.person_add, color: Colors.white),
                          SizedBox(width: 10),
                          Text(
                            "Sign Up",
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: screenHeight * 0.05), // Bottom padding
              // Footer
              const Text(
                "Powered by Finance GPT",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}