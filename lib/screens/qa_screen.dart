import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../api_config.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
enum QuestionMode {
  fromExistingData,
  fromFile,
}

class QAScreen extends HookWidget {
  @override
  Widget build(BuildContext context) {
    // --- Hooks for state ---
    final question = useState<String>('');
    final isLoading = useState<bool>(false);
    final response = useState<Map<String, dynamic>?>(null);
    final cachedResponses = useMemoized(() => <String, Map<String, dynamic>>{}, []);
    
    final _questionMode = useState<QuestionMode>(QuestionMode.fromExistingData);
    final selectedFile = useState<File?>(null);

    // Memoize the URI so it isn't recreated each build
    final questionUri = useMemoized(
      () => Uri.parse('${ApiConfig.baseUrlqa}/question'),
      [],
    );
    final questionUri2 = useMemoized(
      () => Uri.parse('${ApiConfig.baseUrlqa}/ask_pdf'),
      [],
    );
    // sendRequest callback
    final sendRequest = useCallback(() async {
      final q = question.value.trim();
      if (q.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Please enter a question.')));
        return;
      }

      // Check if the response is cached for this question
      if (cachedResponses.containsKey(q)) {
        response.value = cachedResponses[q];
        print('Answer fetched from cache! ${jsonEncode(response.value ?? {})}');
        print("Retrived from cache.");
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Answer fetched from cache!')));
        return;
      }

      isLoading.value = true;
      try {
        final resp = await http.post(
          (_questionMode.value == QuestionMode.fromExistingData) ? questionUri : questionUri2,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'question': q}),
        );
        if (resp.statusCode == 200) {
          final newResponse = json.decode(resp.body) as Map<String, dynamic>;
          // Store the response in the cache
          cachedResponses[q] = newResponse;
          response.value = newResponse;
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: ${resp.statusCode}')));
        }
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Network error: $e')));
      } finally {
        isLoading.value = false;
      }
    }, [questionUri, question.value, cachedResponses]);

    // File picker function (for selecting PDF file)
    Future<void> pickFile() async {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.files.single.path != null) {
        selectedFile.value = File(result.files.single.path!);
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
        title: const Text('Question and Answers'),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Choose your mode:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ListTile(
              title: const Text("Use Existing Data"),
              leading: Radio<QuestionMode>(
                value: QuestionMode.fromExistingData,
                groupValue: _questionMode.value,
                onChanged: (QuestionMode? value) {
                  _questionMode.value = value!;
                  selectedFile.value = null;  // Clear selected file when switching modes
                },
              ),
            ),
            // ListTile(
            //   title: const Text("Upload PDF"),
            //   leading: Radio<QuestionMode>(
            //     value: QuestionMode.fromFile,
            //     groupValue: _questionMode.value,
            //     onChanged: (QuestionMode? value) {
            //       _questionMode.value = value!;
            //     },
            //   ),
            // ),
            // FilepickerUI
            if (_questionMode.value == QuestionMode.fromFile) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: pickFile,
                icon: const Icon(Icons.upload_file),
                label: const Text("Select PDF"),
              ),
              if (selectedFile.value != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    "Selected: ${selectedFile.value!.path.split('/').last}",
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
            ],
            const SizedBox(height: 16),
            const Text('Enter your question', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              onChanged: (val) => question.value = val,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => sendRequest(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading.value ? null : sendRequest,
                child: isLoading.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Submit'),
              ),
            ),
            const SizedBox(height: 24),
            if (response.value != null) ...[
              const Text('Response:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _Section(title: 'Result', content: response.value!['result']?.toString() ?? 'N/A'),
              const SizedBox(height: 8),
              _Section(title: 'Program', content: response.value!['program'] ?? 'N/A'),
              const SizedBox(height: 8),
              _Section(
                title: 'Gold Inds',
                contentWidget: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...?response.value!['gold_inds']?.map<Widget>((e) => Text('• $e')),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String? content;
  final Widget? contentWidget;
  const _Section({required this.title, this.content, this.contentWidget, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final child = contentWidget ?? Text(content ?? 'N/A');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}
