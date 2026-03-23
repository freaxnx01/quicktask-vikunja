import 'package:flutter/material.dart';
import '../data/secure_storage.dart';
import '../data/vikunja_repository.dart';

class SetupScreen extends StatefulWidget {
  final SecureStorage storage;
  final VikunjaRepository repository;
  final VoidCallback onConnected;

  const SetupScreen({
    super.key,
    required this.storage,
    required this.repository,
    required this.onConnected,
  });

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _urlController = TextEditingController();
  final _tokenController = TextEditingController();
  bool _isLoading = false;
  bool _tokenVisible = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final url = await widget.storage.instanceUrl;
    final token = await widget.storage.apiToken;
    if (url != null) _urlController.text = url;
    if (token != null) _tokenController.text = token;
  }

  Future<void> _connect() async {
    final url = _urlController.text.trim();
    final token = _tokenController.text.trim();

    if (url.isEmpty || token.isEmpty) {
      setState(() => _error = 'Both fields are required');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    await widget.storage.setInstanceUrl(url);
    await widget.storage.setApiToken(token);

    final valid = await widget.repository.validateCredentials();
    if (valid) {
      widget.onConnected();
    } else {
      await widget.storage.clear();
      setState(() {
        _isLoading = false;
        _error = 'Connection failed. Check your URL and API token.';
      });
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'QuickTask Setup',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'Instance URL',
                  hintText: 'https://vikunja.example.com',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
                onChanged: (_) => setState(() => _error = null),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _tokenController,
                decoration: InputDecoration(
                  labelText: 'API Token',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _tokenVisible ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setState(() => _tokenVisible = !_tokenVisible),
                  ),
                ),
                obscureText: !_tokenVisible,
                onChanged: (_) => setState(() => _error = null),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isLoading ? null : _connect,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Connect'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
