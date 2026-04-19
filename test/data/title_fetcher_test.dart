import 'package:flutter_test/flutter_test.dart';
import 'package:quicktask_vikunja/data/title_fetcher.dart';

void main() {
  final fetcher = TitleFetcher();

  group('isUrl', () {
    test('accepts plain http and https URLs', () {
      expect(fetcher.isUrl('https://example.com'), isTrue);
      expect(fetcher.isUrl('http://example.com'), isTrue);
    });

    test('accepts URLs with paths, query strings, and fragments', () {
      expect(fetcher.isUrl('https://example.com/foo'), isTrue);
      expect(fetcher.isUrl('https://example.com/foo?a=1&b=2'), isTrue);
      expect(fetcher.isUrl('https://example.com/foo#section'), isTrue);
    });

    test('trims surrounding whitespace before matching', () {
      expect(fetcher.isUrl('  https://example.com  '), isTrue);
      expect(fetcher.isUrl('\nhttps://example.com\n'), isTrue);
    });

    test('rejects non-URL text', () {
      expect(fetcher.isUrl('Buy milk'), isFalse);
      expect(fetcher.isUrl(''), isFalse);
      expect(fetcher.isUrl('example.com'), isFalse,
          reason: 'requires explicit scheme so plain text is not misclassified');
      expect(fetcher.isUrl('ftp://example.com'), isFalse,
          reason: 'only http(s) is treated as a fetchable URL');
    });

    test('rejects URLs with embedded whitespace', () {
      expect(fetcher.isUrl('https://example.com hello'), isFalse);
    });
  });

  group('shortenUrl', () {
    test('returns host without leading www.', () {
      expect(TitleFetcher.shortenUrl('https://www.example.com/foo'), 'example.com');
      expect(TitleFetcher.shortenUrl('https://www.sub.example.com/foo'),
          'sub.example.com');
    });

    test('keeps host as-is when no www. prefix', () {
      expect(TitleFetcher.shortenUrl('https://reisereporter.de/article/x'),
          'reisereporter.de');
    });

    test('returns the original input when the URL has no host', () {
      expect(TitleFetcher.shortenUrl('not a url at all'), 'not a url at all');
    });

    test('returns the original input for a scheme with no host', () {
      expect(TitleFetcher.shortenUrl('https://'), 'https://');
    });
  });

  group('resolveTask', () {
    test('returns raw text untouched when not a URL', () async {
      final result = await fetcher.resolveTask('Buy milk', null);
      expect(result.title, 'Buy milk');
      expect(result.url, isNull);
    });

    test('uses extraSubject as title when provided alongside a URL', () async {
      // Don't actually fetch the page: passing extraSubject short-circuits.
      final result = await fetcher.resolveTask(
        'https://example.com/article',
        'Article subject from share sheet',
      );
      expect(result.title, 'Article subject from share sheet');
      expect(result.url, 'https://example.com/article');
    });
  });
}
