import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

class TitleFetcher {
  static final _urlPattern = RegExp(r'^https?://\S+$', caseSensitive: false);
  static const _timeout = Duration(seconds: 5);

  bool isUrl(String text) => _urlPattern.hasMatch(text.trim());

  Future<String> resolveTaskName(String sharedText, String? extraSubject) async {
    final text = sharedText.trim();
    if (!isUrl(text)) return text;

    if (extraSubject != null && extraSubject.trim().isNotEmpty) {
      return '${extraSubject.trim()} - $text';
    }

    try {
      final response = await http.get(Uri.parse(text)).timeout(_timeout);
      if (response.statusCode == 200) {
        final document = html_parser.parse(response.body);
        final titleElement = document.querySelector('title');
        if (titleElement != null && titleElement.text.trim().isNotEmpty) {
          return '${titleElement.text.trim()} - $text';
        }
      }
    } catch (_) {
      // Fall back to raw URL
    }
    return text;
  }
}
