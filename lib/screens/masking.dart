import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import '../api_config.dart';

enum ViewMode { original, masked, sideBySide }

class MaskingPage extends HookWidget {
  const MaskingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final apiHost = ApiConfig.baseUrlimg;
    
    // State using hooks
    final isLoading = useState(false);
    final originalText = useState<String>('');
    final maskedText = useState<String>('');
    final selectedFile = useState<File?>(null);
    final selectedFileName = useState<String>('');
    final viewMode = useState<ViewMode>(ViewMode.masked);
    final textController = useTextEditingController();

    // Cache maps
    final textCache = useMemoized(() => <String, String>{}, []);
    final fileCache = useMemoized(() => <String, String>{}, []);

    // File picker
    final pickFile = useCallback(() async {
      final typeGroup = XTypeGroup(label: 'Documents', extensions: ['txt', 'doc', 'docx', 'pdf']);
      final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);
      if (file != null) {
        final f = File(file.path);
        selectedFile.value = f;
        selectedFileName.value = file.name;
        final content = await f.readAsString();
        originalText.value = content;
        maskedText.value = '';
      }
    }, []);

    // Process text
    final processText = useCallback(() async {
      final input = textController.text;
      if (input.isEmpty) {
        showError(context, 'Please enter text to process');
        return;
      }
      originalText.value = input;
      maskedText.value = '';

      // use cache
      if (textCache.containsKey(input)) {
        maskedText.value = textCache[input]!;
        return;
      }

      isLoading.value = true;
      try {
        final response = await http.post(
          Uri.parse('$apiHost/mask-text'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'text': input}),
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          maskedText.value = data['masked_text'] ?? '';
          textCache[input] = maskedText.value;
        } else {
          showError(context, 'Failed to process text: \${response.statusCode}');
        }
      } catch (e) {
        showError(context, 'Error: \$e');
      } finally {
        isLoading.value = false;
      }
    }, [textController.text]);

    // Process file
    final processFile = useCallback(() async {
      final file = selectedFile.value;
      if (file == null) {
        showError(context, 'Please select a file first');
        return;
      }
      final path = file.path;
      // cache
      if (fileCache.containsKey(path)) {
        maskedText.value = fileCache[path]!;
        return;
      }

      isLoading.value = true;
      try {
        var request = http.MultipartRequest('POST', Uri.parse('$apiHost/mask-file'));
        request.files.add(await http.MultipartFile.fromPath('file', path));
        final streamed = await request.send();
        final resp = await http.Response.fromStream(streamed);
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body);
          maskedText.value = data['masked_text'] ?? '';
          fileCache[path] = maskedText.value;
        } else {
          showError(context, 'Failed to process file: \${resp.statusCode}');
        }
      } catch (e) {
        showError(context, 'Error: \$e');
      } finally {
        isLoading.value = false;
      }
    }, [selectedFile.value]);

    // Save to file
    final saveToFile = useCallback((String content) async {
      if (!await checkPermissions(context)) return;
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final defaultName = selectedFileName.value.isEmpty
          ? 'masked_\$timestamp.txt'
          : 'masked_\$timestamp_\${selectedFileName.value}';
      final name = await promptFileName(context, defaultName);
      if (name == null) return;
      final file = File('\${dir.path}/\$name');
      await file.writeAsString(content);
      showSuccess(context, 'Saved to \${file.path}');
    }, [selectedFileName.value, maskedText.value]);

    // Share
    final shareContent = useCallback((String content) async {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'masked_\${DateTime.now().millisecondsSinceEpoch}.txt';
      final path = '\${dir.path}/\$fileName';
      final file = File(path);
      await file.writeAsString(content);
      await Share.shareXFiles([XFile(path)], text: 'Masked Output');
    }, [maskedText.value]);

    // View builder
    Widget buildTextDisplay(String text) => Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Text(text, maxLines: 100, overflow: TextOverflow.ellipsis),
        ),
      ),
    );

    Widget buildResultView() {
      switch (viewMode.value) {
        case ViewMode.original:
          return buildTextDisplay(originalText.value);
        case ViewMode.masked:
          return buildTextDisplay(maskedText.value);
        case ViewMode.sideBySide:
          return Row(
            children: [
              Expanded(child: buildTextDisplay(originalText.value)),
              const VerticalDivider(),
              Expanded(child: buildTextDisplay(maskedText.value)),
            ],
          );
      }
    }

    // Build UI
    return Scaffold(
      appBar: AppBar(
        title: const Text('PII Masking Tool'),
        actions: [
          IconButton(
            onPressed: () async {
              // health check
              try {
                final r = await http.get(Uri.parse('$apiHost/health'));
                if (r.statusCode == 200) showSuccess(context, 'Server online');
                else showError(context, 'Server: \${r.statusCode}');
              } catch (_) { showError(context, 'Server unreachable'); }
            },
            icon: const Icon(Icons.cloud_done),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(
            controller: textController,
            decoration: const InputDecoration(
              labelText: 'Enter text to mask (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 5,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: isLoading.value ? null : processText,
            child: isLoading.value
                ? const CircularProgressIndicator()
                : const Text('Mask Text'),
          ),
          const Divider(),
          Row(children: [
            Expanded(child: Text(selectedFileName.value.isEmpty
                ? 'No file selected' : selectedFileName.value)),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: pickFile,
              icon: const Icon(Icons.upload_file),
              label: const Text('Choose File'),
            ),
          ]),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: isLoading.value ? null : processFile,
            child: isLoading.value
                ? const CircularProgressIndicator()
                : const Text('Mask File'),
          ),
          const SizedBox(height: 16),
          SegmentedButton<ViewMode>(
            segments: const [
              ButtonSegment(value: ViewMode.original, label: Text('Original')),
              ButtonSegment(value: ViewMode.masked, label: Text('Masked')),
              ButtonSegment(value: ViewMode.sideBySide, label: Text('Side by Side')),
            ],
            selected: {viewMode.value},
            onSelectionChanged: (s) => viewMode.value = s.first,
          ),
          const SizedBox(height: 8),
          buildResultView(),
          const SizedBox(height: 8),
          if (maskedText.value.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: () => saveToFile(maskedText.value),
                  icon: const Icon(Icons.save),
                  label: const Text('Save'),
                ),
                ElevatedButton.icon(
                  onPressed: () => shareContent(maskedText.value),
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                ),
              ],
            ),
        ]),
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

Future<bool> checkPermissions(BuildContext c) async {
  if (Platform.isAndroid) {
    final s = await Permission.storage.request();
    if (!s.isGranted) { showError(c, 'Storage permission required'); return false; }
  }
  return true;
}

Future<String?> promptFileName(BuildContext c, String def) async {
  final ctrl = TextEditingController(text: def);
  return showDialog<String>(
    context: c,
    builder: (_) => AlertDialog(
      title: const Text('Enter file name'),
      content: TextField(controller: ctrl),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(c, ctrl.text), child: const Text('Save')),
      ],
    ),
  );
}
