import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenAIService {
  static const String _apiKey = String.fromEnvironment('OPENAI_PROXY_API_KEY');
  static const String _endpoint = String.fromEnvironment('OPENAI_PROXY_ENDPOINT');

  static Future<String?> generateTrashSummary(String title, List<String> hashtags) async {
    if (_apiKey.isEmpty || _endpoint.isEmpty) {
      return null;
    }

    try {
      final hashtagsText = hashtags.isNotEmpty ? hashtags.join(', ') : 'none';
      
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a witty social media critic. Generate a concise, sarcastic "Why It\'s Trash" summary (max 100 characters) for shared content. Be humorous but not offensive.',
            },
            {
              'role': 'user',
              'content': 'Title: $title\nHashtags: $hashtagsText\n\nGenerate a brief, witty explanation of why this content might be considered "trash".',
            }
          ],
          'max_tokens': 50,
          'temperature': 0.8,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices']?[0]?['message']?['content']?.trim();
        return content?.isNotEmpty == true ? content : null;
      }
    } catch (e) {
      print('Error generating AI summary: $e');
    }
    
    return null;
  }
}