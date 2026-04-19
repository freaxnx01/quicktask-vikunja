import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

class ResolvedTask {
  final String title;
  final String? url;

  ResolvedTask({required this.title, this.url});
}

class TitleFetcher {
  static final _urlPattern = RegExp(r'^https?://\S+$', caseSensitive: false);
  static const _timeout = Duration(seconds: 5);

  bool isUrl(String text) => _urlPattern.hasMatch(text.trim());

  /// Returns a short domain label for a URL, e.g. "reisereporter.de".
  /// Falls back to the original input when the URL has no parseable host —
  /// `Uri.parse` is lenient and returns an empty host instead of throwing.
  static String shortenUrl(String url) {
    try {
      final uri = Uri.parse(url);
      var host = uri.host;
      if (host.isEmpty) return url;
      if (host.startsWith('www.')) host = host.substring(4);
      return host;
    } catch (_) {
      return url;
    }
  }

  Future<ResolvedTask> resolveTask(String sharedText, String? extraSubject) async {
    final text = sharedText.trim();
    if (!isUrl(text)) return ResolvedTask(title: text);

    // Use EXTRA_SUBJECT from the sharing app if available
    if (extraSubject != null && extraSubject.trim().isNotEmpty) {
      return ResolvedTask(title: extraSubject.trim(), url: text);
    }

    // Fetch page title
    try {
      final response = await http.get(Uri.parse(text)).timeout(_timeout);
      if (response.statusCode == 200) {
        final document = html_parser.parse(response.body);
        final titleElement = document.querySelector('title');
        if (titleElement != null && titleElement.text.trim().isNotEmpty) {
          return ResolvedTask(title: titleElement.text.trim(), url: text);
        }
      }
    } catch (_) {
      // Fall back to raw URL
    }
    return ResolvedTask(title: text);
  }
}
