import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../api_config.dart';

class SummarizationScreen extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final selectedFile = useState<File?>(null);
    final isLoading = useState<bool>(false);
    final summaryPoints = useState<List<String>>([]);

    // Helper: compute SHA256 of file bytes
    Future<String> _fileHash(File file) async {
      final bytes = await file.readAsBytes();
      return sha256.convert(bytes).toString();
    }

    // Try load from SharedPreferences
    Future<bool> _loadFromPrefs(String hash) async {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getStringList('summary_$hash');
      if (cached != null) {
        summaryPoints.value = cached;
        return true;
      }
      return false;
    }

    // Save to SharedPreferences
    Future<void> _saveToPrefs(String hash, List<String> points) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('summary_$hash', points);
    }

    final pickFile = useCallback(() async {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png','jpg','jpeg','pdf','docx','txt'],
      );
      if (result != null && result.files.single.path != null) {
        selectedFile.value = File(result.files.single.path!);
        summaryPoints.value = [];
      }
    }, []);

    final summarize = useCallback(() async {
      final file = selectedFile.value;
      if (file == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a file first.")),
        );
        return;
      }
      isLoading.value = true;
      try {
        final hash = await _fileHash(file);
        // 1) try cache
        if (await _loadFromPrefs(hash)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Loaded from cache.")),
          );
          return;
        }
        // 2) call API
        var req = http.MultipartRequest(
          'POST',
          Uri.parse("${ApiConfig.baseUrlsum}/summarize"),
        );
        req.files.add(await http.MultipartFile.fromPath('file', file.path));
        final resp = await req.send();
        if (resp.statusCode == 200) {
          final body = await resp.stream.bytesToString();
          final parsed = json.decode(body);
          List<String> points;
          if (parsed is Map<String, dynamic>) {
            points = parsed.values
              .join(" ")
              .split(RegExp(r'(?<=[.!?])\s+'))
              .where((s) => s.trim().isNotEmpty)
              .toList();
          } else {
            points = ["Unexpected response format."];
          }
          summaryPoints.value = points;
          await _saveToPrefs(hash, points);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: ${resp.statusCode}")),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      } finally {
        isLoading.value = false;
      }
    }, [selectedFile.value]);

    final downloadPdf = useCallback(() async {
      if (summaryPoints.value.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No summary to download.")),
        );
        return;
      }
      final pdf = pw.Document();
      pdf.addPage(pw.Page(build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: summaryPoints.value.map((pt) => pw.Bullet(text: pt)).toList(),
      )));
      await Printing.layoutPdf(onLayout: (_) => pdf.save());
    }, [summaryPoints.value]);

    void showError(BuildContext c, String m) =>
      ScaffoldMessenger.of(c)
          .showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.red));
    void showSuccess(BuildContext c, String m) =>
        ScaffoldMessenger.of(c)
            .showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.green));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Text Summarization"),
        actions: [
          IconButton(
            onPressed: () async {
              // health check
              try {
                final r = await http.get(Uri.parse('${ApiConfig.baseUrlsum}/health'));
                if (r.statusCode == 200) showSuccess(context, 'Server online');
                else showError(context, 'Server: \${r.statusCode}');
              } catch (_) { showError(context, 'Server unreachable'); }
            },
            icon: const Icon(Icons.cloud_done),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          const Text("Upload a File for Summarization"),
          const SizedBox(height: 20),
          if (selectedFile.value != null)
            Text("Selected: ${selectedFile.value!.path.split('/').last}"),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            ElevatedButton.icon(
              onPressed: pickFile,
              icon: const Icon(Icons.upload_file),
              label: const Text("Choose File"),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: isLoading.value ? null : summarize,
              icon: const Icon(Icons.summarize),
              label: const Text("Summarize"),
            ),
          ]),
          const SizedBox(height: 20),
          if (isLoading.value)
            const CircularProgressIndicator()
          else if (summaryPoints.value.isNotEmpty)
            Expanded(child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text("Summary:", style: TextStyle(fontWeight: FontWeight.bold)),
                ...summaryPoints.value.map((pt) => Row(children: [
                  const Text("• "),
                  Expanded(child: Text(pt))
                ]))
              ]),
            ))
          else
            const Text("Summary will appear here."),
          if (summaryPoints.value.isNotEmpty)
            ElevatedButton.icon(
              onPressed: downloadPdf,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text("Download as PDF"),
            ),
        ]),
      ),
    );
  }
}
