import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'classification_screen.dart';
import 'summarization_screen.dart';
import 'options.dart';
import 'image.dart';
import 'qa_screen.dart';
import '../api_config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart'; // Add this for logout redirection

class DashboardScreen extends StatefulWidget {

  final String username;

  DashboardScreen({required this.username});
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // final String backendUrl = "${ApiConfig.baseUrl}/health";
  // bool _isCheckingBackend = false;

  
  String _getUsername() {
    return widget.username; // Use the passed username directly
    // final email = FirebaseAuth.instance.currentUser?.email ?? '';
    // return email.contains('@') ? email.split('@')[0] : email;
  }

  // Future<bool> _isBackendActive() async {
  //   try {
  //     final response = await http.get(Uri.parse(backendUrl));
  //     if (response.statusCode == 200) {
  //       return true;
  //     }
  //   } catch (e) {
  //     print("Error checking backend status: $e");
  //   }
  //   return false;
  // }

  // void _showBackendError() {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text("Server Inactive"),
  //       content: const Text("The backend server is not running. Please try again later."),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: const Text("OK"),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Future<void> _navigateWithBackendCheck(Widget screen) async {
  //   setState(() => _isCheckingBackend = true);
  //   bool isActive = await _isBackendActive();
  //   setState(() => _isCheckingBackend = false);

  //   if (isActive) {
  //     Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  //   } else {
  //     _showBackendError();
  //   }
  // }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Dashboard"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF8EC5FC),
                  Color(0xFFE0C3FC),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 100, 16, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hello, ${_getUsername()}",
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 1),
                Expanded(
                  child: GridView.builder(
                    itemCount: _features.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.95,
                    ),
                    itemBuilder: (context, index) {
                      final feature = _features[index];
                      return _buildGlassFeatureCard(feature);
                    },
                  ),
                ),
              ],
            ),
          ),
          // if (_isCheckingBackend)
          //   Container(
          //     color: Colors.black26,
          //     child: const Center(
          //       child: CircularProgressIndicator(color: Colors.white),
          //     ),
          //   ),
        ],
      ),
    );
  }

  Widget _buildGlassFeatureCard(_Feature feature) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => feature.screen)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(feature.icon, size: 48, color: Colors.white),
                const SizedBox(height: 12),
                Text(
                  feature.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black45,
                        offset: Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Feature {
  final String title;
  final IconData icon;
  final Color color;
  final Widget screen;

  _Feature({
    required this.title,
    required this.icon,
    required this.color,
    required this.screen,
  });
}

final List<_Feature> _features = [
  _Feature(
    title: "Classification",
    icon: Icons.category,
    color: Colors.blue,
    screen: ClassificationScreen(),
  ),
  _Feature(
    title: "Q&A",
    icon: Icons.question_answer,
    color: Colors.green,
    screen: QAScreen(),
  ),
  _Feature(
    title: "Masking",
    icon: Icons.visibility_off,
    color: Colors.orange,
    screen: MaskingOptionsPage(),
  ),
  _Feature(
    title: "Summarization",
    icon: Icons.summarize,
    color: Colors.purple,
    screen: SummarizationScreen(),
  ),
];
