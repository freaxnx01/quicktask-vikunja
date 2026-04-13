import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  final _storage = const FlutterSecureStorage();

  static const _keyInstanceUrl = 'instance_url';
  static const _keyApiToken = 'api_token';

  Future<String?> get instanceUrl => _storage.read(key: _keyInstanceUrl);
  Future<String?> get apiToken => _storage.read(key: _keyApiToken);

  Future<void> setInstanceUrl(String url) async {
    final normalized = _normalizeUrl(url);
    await _storage.write(key: _keyInstanceUrl, value: normalized);
  }

  Future<void> setApiToken(String token) async {
    await _storage.write(key: _keyApiToken, value: token);
  }

  Future<bool> get isConfigured async {
    final url = await instanceUrl;
    final token = await apiToken;
    return url != null && url.isNotEmpty && token != null && token.isNotEmpty;
  }

  Future<void> clear() async {
    await _storage.delete(key: _keyInstanceUrl);
    await _storage.delete(key: _keyApiToken);
  }

  String _normalizeUrl(String url) {
    var trimmed = url.trim();
    if (trimmed.endsWith('/')) trimmed = trimmed.substring(0, trimmed.length - 1);
    if (!trimmed.contains('://')) trimmed = 'https://$trimmed';
    return trimmed;
  }
}
