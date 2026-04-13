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
  String? _pendingSharedText;

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
    // Handle share intent when app is already running
    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen((value) {
      if (value.isNotEmpty && value.first.path.isNotEmpty) {
        _handleSharedText(value.first.path);
      }
    });

    // Handle share intent that started the app
    ReceiveSharingIntent.instance.getInitialMedia().then((value) {
      if (value.isNotEmpty && value.first.path.isNotEmpty) {
        _handleSharedText(value.first.path);
        ReceiveSharingIntent.instance.reset();
      }
    });
  }

  void _navigateToProjectPicker(String text) {
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProjectPickerScreen(
            sharedText: text,
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
  }

  void _handleSharedText(String text) async {
    final configured = await _storage.isConfigured;
    if (!configured) {
      setState(() {
        _pendingSharedText = text;
        _showSetup = true;
      });
      return;
    }

    _navigateToProjectPicker(text);
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
          if (_pendingSharedText != null) {
            final text = _pendingSharedText!;
            _pendingSharedText = null;
            _handleSharedText(text);
          }
        },
      );
    }

    return RecentTasksScreen(
      taskHistory: _taskHistory,
      onSettingsClick: () => setState(() => _showSetup = true),
      onAddTask: _navigateToProjectPicker,
    );
  }
}
