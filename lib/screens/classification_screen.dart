import 'dart:typed_data';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:crypto/crypto.dart';
import '../api_config.dart'; 




// Custom Hook for Prediction Cache
Map<String, Map<String, dynamic>> useCustomPredictionCache() {
  return useMemoized(() => <String, Map<String, dynamic>>{}, []);
}

class ClassificationScreen extends HookWidget {
  const ClassificationScreen({Key? key}) : super(key: key);

  @override

  Widget build(BuildContext context) {
    final _selectedFileBytes = useState<Uint8List?>(null);
    final _selectedFileName = useState<String?>(null);
    final _prediction = useState<String?>(null);
    final _confidence = useState<double?>(null);
    final _isLoading = useState<bool>(false);
    final _imageFile = useState<File?>(null);
    // final textController = useTextEditingController();
    // final focusNode = useFocusNode();
    final ImagePicker picker = ImagePicker();
    final _predictionCache = useCustomPredictionCache();

    useEffect(() {
      if (_prediction.value != null) {
        print("New prediction: ${_prediction.value}");
      }
      return null;
    }, [_prediction.value]);

    String _generateFileHash(File file) {
      List<int> bytes = file.readAsBytesSync();
      return sha256.convert(bytes).toString();
    }

    Future<void> _pickFile({bool isImage = false}) async {
      try {
        if (isImage) {
          final pickedFile = await picker.pickImage(source: ImageSource.gallery);
          if (pickedFile != null) {
            _imageFile.value = File(pickedFile.path);
            _selectedFileName.value = pickedFile.name;
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("No image selected.")),
            );
          }
        } else {
          FilePickerResult? result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'png', 'jpeg'],
          );

          if (result != null && result.files.isNotEmpty) {
            final filePath = result.files.single.path;
            if (filePath != null) {
              _selectedFileBytes.value = await File(filePath).readAsBytes();
              _selectedFileName.value = result.files.single.name;
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Failed to read the file.")),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("No document selected.")),
            );
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("File picking error: $e")),
        );
      }
    }

    Future<void> _uploadAndPredict() async {
      if (_imageFile.value == null && _selectedFileBytes.value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No file selected.")),
        );
        return;
      }

      String fileHash = _imageFile.value != null
          ? _generateFileHash(_imageFile.value!)
          : sha256.convert(_selectedFileBytes.value!).toString();

      if (_predictionCache[fileHash] != null) {
        _prediction.value = _predictionCache[fileHash]!['prediction'];
        _confidence.value = _predictionCache[fileHash]!['confidence'];
        return;
      }

      _isLoading.value = true;

      try {
        String urlString = "${ApiConfig.baseUrlqa}/predict";
        Uri uri = Uri.parse(urlString.trim());

        final request = http.MultipartRequest('POST', uri)
          ..headers['accept'] = 'application/json'
          ..headers['Content-Type'] = 'multipart/form-data';

        if (_imageFile.value != null) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'file',
              _imageFile.value!.path,
              contentType: MediaType('image', 'jpeg'),
            ),
          );
        } else if (_selectedFileBytes.value != null) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'file',
              _selectedFileBytes.value!,
              filename: _selectedFileName.value,
              contentType: MediaType.parse(lookupMimeType(_selectedFileName.value!) ?? 'application/octet-stream'),
            ),
          );
        }

        final response = await request.send();
        if (response.statusCode == 200) {
          final responseData = await response.stream.bytesToString();
          final predictionData = jsonDecode(responseData);
          _prediction.value = predictionData['prediction'];
          _confidence.value = predictionData['confidence'];

          _predictionCache[fileHash] = {
            'prediction': _prediction.value,
            'confidence': _confidence.value,
          };
        } else {
          _prediction.value = "Prediction Failed";
        }
      } catch (e) {
        _prediction.value = "Error: $e";
      } finally {
        _isLoading.value = false;
      }
    }

    void showError(BuildContext c, String m) =>
    ScaffoldMessenger.of(c)
        .showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.red));
    void showSuccess(BuildContext c, String m) =>
        ScaffoldMessenger.of(c)
            .showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.green));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Doc Classification", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () async {
              // health check
              try {
                final r = await http.get(Uri.parse('${ApiConfig.baseUrlqa}/health'));
                if (r.statusCode == 200) showSuccess(context, 'Server online');
                else showError(context, 'Server: \${r.statusCode}');
              } catch (_) { showError(context, 'Server unreachable'); }
            },
            icon: const Icon(Icons.cloud_done),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Upload an Image or Document",
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              if (_selectedFileName.value != null)
                Text(
                  "Selected: ${_selectedFileName.value}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _pickFile(isImage: true),
                    icon: const Icon(Icons.image),
                    label: const Text("Pick Image"),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () => _pickFile(isImage: false),
                    icon: const Icon(Icons.file_present),
                    label: const Text("Pick Document"),
                  ),
                ],
              ),
              // const SizedBox(height: 20),
              // TextField(
              //   controller: textController,
              //   focusNode: focusNode,
              //   decoration: const InputDecoration(
              //     labelText: 'Optional Notes',
              //     border: OutlineInputBorder(),
              //   ),
              // ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading.value ? null : _uploadAndPredict,
                child: _isLoading.value
                    ? const CircularProgressIndicator()
                    : const Text("Classify Document"),
              ),
              const SizedBox(height: 20),
              if (_prediction.value != null)
                Column(
                  children: [
                    Text(
                      _prediction.value!,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_confidence.value != null)
                      Text(
                        "Confidence: ${(_confidence.value! * 100).toStringAsFixed(2)}%",
                        style: const TextStyle(color: Colors.green, fontSize: 16),
                      ),
                    const SizedBox(height: 20),
                    if (_imageFile.value != null)
                      Image.file(
                        _imageFile.value!,
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                  ],
                ),
              const SizedBox(height: 30),
              const Text(
                "Prediction Cache",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _predictionCache.length,
                itemBuilder: (context, index) {
                  final entry = _predictionCache.entries.elementAt(index);
                  final fileHash = entry.key;
                  final data = entry.value;
                  return Card(
                    elevation: 2,
                    child: ListTile(
                      title: Text("Prediction: ${data['prediction']}"),
                      subtitle: Text(
                        "Confidence: ${(data['confidence'] * 100).toStringAsFixed(2)}%\nHash: ${fileHash.substring(0, 10)}...",
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
