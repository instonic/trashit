import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;

class UrlMetadata {
  final String title;
  final String imageUrl;
  final List<String> hashtags;

  UrlMetadata({
    required this.title,
    required this.imageUrl,
    required this.hashtags,
  });
}

class UrlMetadataService {
  static Future<UrlMetadata> extractMetadata(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (compatible; Trashit/1.0)',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final document = html_parser.parse(response.body);
        
        // Extract title
        String title = '';
        final titleElement = document.querySelector('title');
        final ogTitle = document.querySelector('meta[property="og:title"]');
        final twitterTitle = document.querySelector('meta[name="twitter:title"]');
        
        if (ogTitle != null) {
          title = ogTitle.attributes['content'] ?? '';
        } else if (twitterTitle != null) {
          title = twitterTitle.attributes['content'] ?? '';
        } else if (titleElement != null) {
          title = titleElement.text;
        }
        
        // Extract image
        String imageUrl = '';
        final ogImage = document.querySelector('meta[property="og:image"]');
        final twitterImage = document.querySelector('meta[name="twitter:image"]');
        
        if (ogImage != null) {
          imageUrl = ogImage.attributes['content'] ?? '';
        } else if (twitterImage != null) {
          imageUrl = twitterImage.attributes['content'] ?? '';
        }
        
        // Extract hashtags from description or content
        List<String> hashtags = [];
        final description = document.querySelector('meta[name="description"]')?.attributes['content'] ?? '';
        final ogDescription = document.querySelector('meta[property="og:description"]')?.attributes['content'] ?? '';
        
        final text = '$title $description $ogDescription'.toLowerCase();
        final hashtagRegex = RegExp(r'#(\w+)');
        final matches = hashtagRegex.allMatches(text);
        hashtags = matches.map((match) => '#${match.group(1)}').toSet().toList();
        
        // If no hashtags found, generate some based on the domain
        if (hashtags.isEmpty) {
          final uri = Uri.parse(url);
          final domain = uri.host.toLowerCase();
          if (domain.contains('twitter') || domain.contains('x.com')) {
            hashtags.add('#twitter');
          } else if (domain.contains('instagram')) {
            hashtags.add('#instagram');
          } else if (domain.contains('tiktok')) {
            hashtags.add('#tiktok');
          } else if (domain.contains('youtube')) {
            hashtags.add('#youtube');
          } else if (domain.contains('facebook')) {
            hashtags.add('#facebook');
          } else {
            hashtags.add('#socialmedia');
          }
        }
        
        return UrlMetadata(
          title: title.isNotEmpty ? title : 'Shared Content',
          imageUrl: imageUrl.isNotEmpty ? imageUrl : _getPlaceholderImage(),
          hashtags: hashtags.take(5).toList(),
        );
      }
    } catch (e) {
      print('Error extracting metadata: $e');
    }
    
    // Return default metadata if extraction fails
    return UrlMetadata(
      title: 'Shared Content',
      imageUrl: _getPlaceholderImage(),
      hashtags: ['#shared'],
    );
  }

  static String _getPlaceholderImage() {
    return 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400&h=300&fit=crop';
  }
}