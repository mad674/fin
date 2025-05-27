import 'package:flutter/material.dart';
import 'masking.dart';
import 'image.dart'; // Assuming this is the path to your image.dart file
import 'dart:math' as math;

class MaskingOptionsPage extends StatelessWidget {
  const MaskingOptionsPage({Key? key}) : super(key: key);

  // Define as static constants for use throughout the class
  static const Color newPrimary = Color(0xFF2E7D32); // Dark green primary
  static const Color newAccent = Color(0xFF66BB6A); // Light green accent
  static const Color newText = Color(0xFF263238); // Dark text
  static const Color newTextLight = Color(0xFF78909C); // Medium gray text

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Masking Options',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: newPrimary,
        foregroundColor: Colors.white,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFF0C0C0C), // Black background
        child: Stack(
          children: [
            // Wavy background
            const Positioned.fill(
              child: WavyBackground(),
            ),
            
            // Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    const Text(
                      'Select Masking Type',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Choose the type of content you want to mask',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Options
                    _buildOptionCard(
                      context: context,
                      icon: Icons.text_fields,
                      title: 'Text Masking',
                      description: 'Mask sensitive information in text documents',
                      color: newAccent.withOpacity(0.2),
                      iconColor: newPrimary,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MaskingPage(),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    _buildOptionCard(
                      context: context,
                      icon: Icons.image,
                      title: 'Image Masking',
                      description: 'Mask sensitive information in images',
                      color: newAccent.withOpacity(0.2),
                      iconColor: newPrimary,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ImageMaskingPage(), // Make sure this matches your actual class name
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: iconColor.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color,
              Color.lerp(color, Colors.black, 0.1) ?? color,
            ],
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withOpacity(0.3),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: iconColor, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: MaskingOptionsPage.newText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: MaskingOptionsPage.newTextLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: MaskingOptionsPage.newTextLight,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// Reusing the WavyBackground from home_screen.dart
class WavyBackground extends StatelessWidget {
  const WavyBackground({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: WaveBackgroundPainter(),
      size: Size.infinite,
    );
  }
}

// Custom painter for wavy background (same as in home_screen.dart)
class WaveBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    
    // Define colors for wave layers
    const color1 = Color(0xFF0D1F12); // Dark green
    const color2 = Color(0xFF0A3B0F); // Medium green
    const color3 = Color(0xFF194D1C); // Lighter green
    
    // Draw back layer (darkest wave)
    _drawSingleWave(
      canvas: canvas, 
      width: width,
      height: height,
      color: color1,
      amplitude: height * 0.3,
      frequency: 1.5,
      phase: 0.0,
      verticalPosition: height * 0.7
    );
    
    // Draw middle layer
    _drawSingleWave(
      canvas: canvas, 
      width: width,
      height: height,
      color: color2,
      amplitude: height * 0.25,
      frequency: 2.0,
      phase: 0.5,
      verticalPosition: height * 0.75
    );
    
    // Draw front layer (lightest wave)
    _drawSingleWave(
      canvas: canvas, 
      width: width,
      height: height,
      color: color3,
      amplitude: height * 0.15,
      frequency: 3.0,
      phase: 1.0,
      verticalPosition: height * 0.8
    );
  }
  
  void _drawSingleWave({
    required Canvas canvas,
    required double width,
    required double height,
    required Color color,
    required double amplitude,
    required double frequency,
    required double phase,
    required double verticalPosition,
  }) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final path = Path();
    
    // Start at bottom left
    path.moveTo(0, height);
    
    // Draw wave pattern
    for (int i = 0; i <= width.toInt(); i++) {
      final x = i.toDouble();
      final scaling = 2 * math.pi * frequency / width;
      final y = verticalPosition - amplitude * math.sin((x * scaling) + phase);
      path.lineTo(x, y);
    }
    
    // Complete the shape
    path.lineTo(width, height);
    path.close();
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}