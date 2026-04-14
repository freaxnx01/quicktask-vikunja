import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'data/secure_storage.dart';
import 'data/vikunja_api.dart';
import 'data/vikunja_repository.dart';
import 'data/title_fetcher.dart';
import 'data/project_usage_tracker.dart';
import 'data/task_history.dart';
import 'models/shared_content.dart';
import 'ui/setup_screen.dart';
import 'ui/recent_tasks_screen.dart';
import 'ui/project_picker_screen.dart';

bool get _isMobile =>
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS;

void main() {
  runApp(const QuickTaskApp());
}

class QuickTaskApp extends StatelessWidget {
  const QuickTaskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuickTask',
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _storage = SecureStorage();
  late final _api = VikunjaApi(_storage);
  late final _repository = VikunjaRepository(_api);
  final _titleFetcher = TitleFetcher();
  final _usageTracker = ProjectUsageTracker();
  final _taskHistory = TaskHistory();

  bool _isConfigured = false;
  bool _showSetup = false;
  bool _loading = true;

  StreamSubscription? _intentSub;
  SharedContent? _pendingShared;

  @override
  void initState() {
    super.initState();
    _checkConfig();
    if (_isMobile) _setupShareListener();
  }

  Future<void> _checkConfig() async {
    final configured = await _storage.isConfigured;
    setState(() {
      _isConfigured = configured;
      _showSetup = !configured;
      _loading = false;
    });
  }

  void _setupShareListener() {
    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen(_handleShared);
    ReceiveSharingIntent.instance.getInitialMedia().then((value) {
      if (value.isNotEmpty) {
        _handleShared(value);
        ReceiveSharingIntent.instance.reset();
      }
    });
  }

  SharedContent _toSharedContent(List<SharedMediaFile> media) {
    String? text;
    final files = <SharedFile>[];
    for (final m in media) {
      if (m.type == SharedMediaType.text || m.type == SharedMediaType.url) {
        // For text/url shares the plugin puts the payload in `path`.
        if (m.path.isNotEmpty) text ??= m.path;
      } else {
        if (m.path.isNotEmpty) files.add(SharedFile.fromPath(m.path));
      }
    }
    return SharedContent(text: text, files: files);
  }

  void _navigateToProjectPicker(SharedContent content) {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProjectPickerScreen(
          shared: content,
          repository: _repository,
          titleFetcher: _titleFetcher,
          usageTracker: _usageTracker,
          taskHistory: _taskHistory,
          onDone: () {
            Navigator.of(context).pop();
            setState(() {});
          },
        ),
      ),
    );
  }

  void _handleShared(List<SharedMediaFile> media) async {
    if (media.isEmpty) return;
    final content = _toSharedContent(media);
    if (!content.hasText && !content.hasFiles) return;

    final configured = await _storage.isConfigured;
    if (!configured) {
      setState(() {
        _pendingShared = content;
        _showSetup = true;
      });
      return;
    }
    _navigateToProjectPicker(content);
  }

  @override
  void dispose() {
    _intentSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_showSetup || !_isConfigured) {
      return SetupScreen(
        storage: _storage,
        repository: _repository,
        onConnected: () {
          setState(() {
            _isConfigured = true;
            _showSetup = false;
          });
          if (_pendingShared != null) {
            final content = _pendingShared!;
            _pendingShared = null;
            _navigateToProjectPicker(content);
          }
        },
      );
    }

    return RecentTasksScreen(
      taskHistory: _taskHistory,
      onSettingsClick: () => setState(() => _showSetup = true),
      onAddTask: (text) => _navigateToProjectPicker(SharedContent(text: text)),
    );
  }
}
