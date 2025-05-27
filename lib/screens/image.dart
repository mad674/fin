import 'dart:io';
import 'dart:convert';
import 'dart:typed_data'; // Import for Uint8List
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:math' as math;
import '../api_config.dart'; // Import your API config file
import 'package:photo_view/photo_view.dart'; // Import for zoomable image view
import 'package:flutter_image_slideshow/flutter_image_slideshow.dart'; // Import for image slideshow
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart'; // Import for sharing images
class ImageService {
  // Base URL for API calls
  final String baseUrl = "${ApiConfig.baseUrlimg}"; // Replace with your backend URL
  // Method to predict document type
  // Future<Map<String, dynamic>?> predictDocumentType() async {
  //   try {
  //     // Pick image from gallery
  //     final picker = ImagePicker();
  //     final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      
  //     if (pickedFile == null) return null;
      
  //     // Create multipart request for the prediction endpoint
  //     var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/predict'));
  //     request.files.add(await http.MultipartFile.fromPath('file', pickedFile.path));
      
  //     // Send request
  //     print('Sending document prediction request to $baseUrl/predict');
  //     var response = await request.send();
  //     print('Response status: ${response.statusCode}');
      
  //     if (response.statusCode == 200) {
  //       var responseData = await response.stream.bytesToString();
  //       final result = jsonDecode(responseData);
  //       print('Prediction response: $result');
        
  //       // Add image path to result for UI display
  //       result['imagePath'] = pickedFile.path;
  //       return result;
  //     } else {
  //       throw Exception('Document prediction failed with status ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     print('Error in document prediction: $e');
  //     return null;
  //   }
  // }
  // // Method to summarize document content
  // Future<Map<String, dynamic>?> summarizeDocument() async {
  //   try {
  //     // Pick document file
  //     final picker = ImagePicker();
  //     final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      
  //     if (pickedFile == null) return null;
      
  //     // Create multipart request for the summarization endpoint
  //     var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/summarize'));
  //     request.files.add(await http.MultipartFile.fromPath('file', pickedFile.path));
      
  //     // Send request
  //     print('Sending summarization request to $baseUrl/summarize/');
  //     var response = await request.send();
  //     print('Response status: ${response.statusCode}');
      
  //     if (response.statusCode == 200) {
  //       var responseData = await response.stream.bytesToString();
  //       final result = jsonDecode(responseData);
  //       print('Summarization response: $result');
        
  //       // Add image path to result for UI display
  //       result['imagePath'] = pickedFile.path;
  //       return result;
  //     } else {
  //       throw Exception('Document summarization failed with status ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     print('Error in document summarization: $e');
  //     return null;
  //   }
  // }
  
  // Method to pick a file with custom source and type options
  Future<File?> pickFile({required ImageSource source, List<String>? allowedExtensions}) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);
      
      if (pickedFile == null) return null;
      
      final file = File(pickedFile.path);
      
      // Check if file extension is allowed
      if (allowedExtensions != null) {
        final extension = pickedFile.path.split('.').last.toLowerCase();
        if (!allowedExtensions.contains(extension)) {
          print('File type not allowed: $extension');
          return null;
        }
      }
      
      return file;
    } catch (e) {
      print('Error picking file: $e');
      return null;
    }
  }

  // Method to mask sensitive information in an image
  Future<Map<String, dynamic>?> maskImage(File imageFile) async {
    try {
      // Determine the content type dynamically
      final contentType = MediaType('image', _getImageSubtype(imageFile.path));

      // Create multipart request for the masking endpoint
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/mask-image'));
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        contentType: contentType,
      ));

      // Send request
      print('Sending image masking request to $baseUrl/mask-image');
      var response = await request.send();
      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        final result = jsonDecode(responseData);
        print('Image masking response: $result');

        // Add original image path to result for UI display
        result['originalImagePath'] = imageFile.path;
        return result;
      } else {
        throw Exception('Image masking failed with status ${response.statusCode}');
      }
    } catch (e) {
      print('Error in image masking: $e');
      return null;
    }
  }

  String _getImageSubtype(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'jpeg';
      case 'png':
        return 'png';
      case 'mp4':
        return 'mp4'; // If you want to handle videos
      default:
        throw Exception('Unsupported file type: $extension');
    }
  }
}

// Image Masking Page UI
class ImageMaskingPage extends StatefulWidget {
  const ImageMaskingPage({Key? key}) : super(key: key);

  @override
  State<ImageMaskingPage> createState() => _ImageMaskingPageState();
}

class _ImageMaskingPageState extends State<ImageMaskingPage> {
  final ImageService _imageService = ImageService();
  File? _selectedImage;
  bool _isLoading = false;
  Map<String, dynamic>? _maskingResult;
  String? _maskedImageBase64;
  bool _showOriginalImage = false; // Default to showing the masked image
  
  // Define new color theme to match home screen
  static const Color newPrimary = Color(0xFF2E7D32); // Dark green primary
  static const Color newAccent = Color(0xFF66BB6A); // Light green accent
  static const Color newBackground = Color(0xFF111111); // Dark/black background
  static const Color newText = Color(0xFF263238); // Dark text
  static const Color newTextLight = Color(0xFF78909C); // Medium gray text

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final file = await _imageService.pickFile(
        source: source,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );
      
      if (file != null) {
        setState(() {
          _selectedImage = file;
          _maskingResult = null;
          _maskedImageBase64 = null; // Reset masked image when selecting a new one
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _processImage() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final result = await _imageService.maskImage(_selectedImage!);
      
      if (result != null) {
        setState(() {
          _maskingResult = result;
          // Extract and store the base64 image data from the response
          if (result.containsKey('masked_image')) {
            _maskedImageBase64 = result['masked_image'];
            print('Received masked image: ${_maskedImageBase64?.substring(0, 50)}...');
          } else {
            print('No masked_image field found in the response');
          }
        });
      } else {
        print('Received null result from maskImage');
      }
    } catch (e) {
      print('Error in _processImage: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing image: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Function to decode and create image from base64
  Widget _buildImageWidget() {
    if (_maskingResult != null && _maskedImageBase64 != null) {
      try {
        // Decode the base64 masked image
        String base64Data = _maskedImageBase64!;
        if (base64Data.contains(',')) {
          base64Data = base64Data.split(',')[1];
        }
        final decodedBytes = base64Decode(base64Data);

        return Column(
          children: [
            Expanded(
              child: PhotoView(
                imageProvider: _showOriginalImage
                    ? FileImage(_selectedImage!)
                    : MemoryImage(decodedBytes) as ImageProvider,
                backgroundDecoration: const BoxDecoration(color: Colors.black),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Toggle between original and masked image
                IconButton(
                  onPressed: () => setState(() {
                    _showOriginalImage = !_showOriginalImage;
                  }),
                  icon: Icon(
                    _showOriginalImage ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white,
                  ),
                  iconSize: 40, // Adjust button size
                ),
                // Share the masked image
                IconButton(
                  onPressed: () async {
                    try {
                      // Decode the base64 image to bytes
                      String base64Data = _maskedImageBase64!;
                      if (base64Data.contains(',')) {
                        base64Data = base64Data.split(',')[1];
                      }
                      final decodedBytes = base64Decode(base64Data);

                      // Save the image temporarily for sharing
                      final directory = await getTemporaryDirectory();
                      final filePath = '${directory.path}/masked_image.png';
                      final file = File(filePath);
                      await file.writeAsBytes(decodedBytes);

                      // Share the image
                      await Share.shareXFiles([XFile(filePath)], text: 'Check out this masked image!');
                    } catch (e) {
                      print('Error sharing masked image: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to share masked image: $e')),
                      );
                    }
                  },
                  icon: const Icon(Icons.share, color: Colors.white),
                  iconSize: 40, // Adjust button size
                ),
              ],
            ),
          ],
        );
      } catch (e) {
        print('Error decoding base64 image: $e');
        return Image.file(
          _selectedImage!,
          fit: BoxFit.contain,
        );
      }
    } else if (_selectedImage != null) {
      return Image.file(
        _selectedImage!,
        fit: BoxFit.contain,
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: 80,
            color: newAccent.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No image selected',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Upload an image to begin masking',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white30,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
  }

  Widget _buildZoomableImage(Uint8List imageBytes) {
    return PhotoView(
      imageProvider: MemoryImage(imageBytes),
      backgroundDecoration: const BoxDecoration(
        color: Colors.black,
      ),
      enableRotation: true,
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * 2,
    );
  }

  Widget _buildSlidingComparison() {
    if (_maskingResult != null && _maskedImageBase64 != null) {
      try {
        // Decode the base64 masked image
        String base64Data = _maskedImageBase64!;
        if (base64Data.contains(',')) {
          base64Data = base64Data.split(',')[1];
        }
        final decodedBytes = base64Decode(base64Data);

        return PhotoView.customChild(
          child: Row(
            children: [
              Expanded(
                child: Image.file(
                  _selectedImage!,
                  fit: BoxFit.contain,
                ),
              ),
              Expanded(
                child: Image.memory(
                  decodedBytes,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        );
      } catch (e) {
        print('Error decoding base64 image: $e');
        return const Center(
          child: Text(
            'Error loading images',
            style: TextStyle(color: Colors.red),
          ),
        );
      }
    } else {
      return const Center(
        child: Text(
          'No images to compare',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
  }

  void showError(BuildContext c, String m) =>
      ScaffoldMessenger.of(c)
          .showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.red));
  void showSuccess(BuildContext c, String m) =>
      ScaffoldMessenger.of(c)
          .showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.green));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Masking', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: newPrimary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () async {
              // health check
              try {
                final r = await http.get(Uri.parse('${ApiConfig.baseUrlimg}/health'));
                if (r.statusCode == 200) showSuccess(context, 'Server online');
                else showError(context, 'Server: \${r.statusCode}');
              } catch (_) { showError(context, 'Server unreachable'); }
            },
            icon: const Icon(Icons.cloud_done),
          ),
        ],
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
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    const Text(
                      'Mask Sensitive Information in Images',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Upload an image to automatically detect and mask sensitive content like personal information, financial data, etc.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    // Image preview area
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: newPrimary.withOpacity(0.3)),
                        ),
                        child: _isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(newAccent),
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: _buildImageWidget(),
                                      ),
                                    ),
                                  ),
                                  if (_maskingResult != null)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: newPrimary.withOpacity(0.2),
                                        borderRadius: const BorderRadius.only(
                                          bottomLeft: Radius.circular(16),
                                          bottomRight: Radius.circular(16),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Processing Complete',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: newAccent,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          if (_maskingResult!.containsKey('masked_count'))
                                            Text(
                                              'Masked ${_maskingResult!['masked_count']} sensitive items',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.white,
                                              ),
                                            ),
                                          if (_maskedImageBase64 == null && _maskingResult!.containsKey('masked_count'))
                                            const Text(
                                              'Image was processed but masked version could not be displayed',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.amber,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.photo_library,
                            label: 'Gallery',
                            onTap: () => _pickImage(ImageSource.gallery),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.camera_alt,
                            label: 'Camera',
                            onTap: () => _pickImage(ImageSource.camera),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.shield,
                            label: 'Mask Image',
                            onTap: _processImage,
                            isPrimary: true,
                          ),
                        ),
                      ],
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        elevation: 6,
        shadowColor: newPrimary.withOpacity(0.5),
        padding: const EdgeInsets.symmetric(vertical: 14),
        backgroundColor: isPrimary ? newPrimary : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: isPrimary ? Colors.white : newPrimary,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isPrimary ? Colors.white : newText,
            ),
          ),
        ],
      ),
    );
  }
  }

// Wavy Background reused from HomeScreen
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

// Custom painter for wavy background
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