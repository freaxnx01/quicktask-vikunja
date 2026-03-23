import 'package:flutter/material.dart';
import '../data/task_history.dart';

class RecentTasksScreen extends StatefulWidget {
  final TaskHistory taskHistory;
  final VoidCallback onSettingsClick;

  const RecentTasksScreen({
    super.key,
    required this.taskHistory,
    required this.onSettingsClick,
  });

  @override
  State<RecentTasksScreen> createState() => _RecentTasksScreenState();
}

class _RecentTasksScreenState extends State<RecentTasksScreen> {
  List<TaskHistoryEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await widget.taskHistory.getEntries();
    setState(() => _entries = entries);
  }

  String _formatRelativeTime(int timestamp) {
    final diff = DateTime.now().millisecondsSinceEpoch - timestamp;
    final minutes = diff ~/ 60000;
    final hours = minutes ~/ 60;
    final days = hours ~/ 24;

    if (minutes < 1) return 'just now';
    if (minutes < 60) return '${minutes}m ago';
    if (hours < 24) return '${hours}h ago';
    if (days < 30) return '${days}d ago';
    return '${days ~/ 30}mo ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QuickTask'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: widget.onSettingsClick,
          ),
        ],
      ),
      body: _entries.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No tasks yet.\nShare a URL or text from another app to get started.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _entries.length,
              itemBuilder: (context, index) {
                final entry = _entries[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.taskName, style: Theme.of(context).textTheme.bodyLarge),
                      Text(
                        '${entry.projectName} • ${_formatRelativeTime(entry.timestamp)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
