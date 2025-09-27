
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Securely access the API key provided at compile time
const String openAiApiKey = String.fromEnvironment('OPENAI_API_KEY');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trashit',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        brightness: Brightness.dark,
      ),
      home: MyHomePage(title: 'Trashit - Analyze & Reject'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _textController = TextEditingController();
  String _analysisResult = '';
  bool _isLoading = false;

  Future<void> _analyzeText() async {
    if (_textController.text.isEmpty) {
      setState(() {
        _analysisResult = 'Please enter some text to analyze.';
      });
      return;
    }

    // This is a critical check. If the API key wasn't provided during the build,
    // the app will fail gracefully instead of making a broken request.
    if (openAiApiKey.isEmpty) {
      setState(() {
        _analysisResult = 'Error: The OPENAI_API_KEY was not provided during the build process. The application developer must configure this.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _analysisResult = '';
    });

    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $openAiApiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a content moderation expert. Analyze the following text for negativity, hate speech, or misinformation. Summarize your findings in a brief, clear, and concise manner. Start your response with one of three labels: [SAFE], [NEGATIVE], or [HATE_SPEECH].'
            },
            {
              'role': 'user',
              'content': _textController.text,
            }
          ],
          'max_tokens': 150,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _analysisResult = data['choices'][0]['message']['content'].trim();
        });
      } else {
        // Provide more detailed error information for debugging
        setState(() {
          _analysisResult = 'Error: Failed to get analysis. Status code: ${response.statusCode}\nResponse Body: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _analysisResult = 'An unexpected error occurred: $e';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.grey[900],
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Enter text to analyze for negativity',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(height: 20),
              TextField(
                controller: _textController,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: 'Paste or type your text here...',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[800],
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _analyzeText,
                child: Text('Analyze Text'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                ),
              ),
              SizedBox(height: 30),
              if (_isLoading)
                CircularProgressIndicator()
              else if (_analysisResult.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    _analysisResult,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
