import 'package:flutter/material.dart';
import '../data/vikunja_repository.dart';
import '../models/vikunja_task.dart';
import 'widgets/version_footer.dart';

class TaskConfirmationScreen extends StatefulWidget {
  final int projectId;
  final String projectName;
  final int createdTaskId;
  final String createdTaskTitle;
  final VikunjaRepository repository;
  final VoidCallback onDone;
  final int attachmentCount;
  final String? attachmentError;
  final Future<void> Function()? retryAttachments;

  const TaskConfirmationScreen({
    super.key,
    required this.projectId,
    required this.projectName,
    required this.createdTaskId,
    required this.createdTaskTitle,
    required this.repository,
    required this.onDone,
    this.attachmentCount = 0,
    this.attachmentError,
    this.retryAttachments,
  });

  @override
  State<TaskConfirmationScreen> createState() => _TaskConfirmationScreenState();
}

class _TaskConfirmationScreenState extends State<TaskConfirmationScreen> {
  List<TaskSummary>? _tasks;
  String? _error;
  late String? _attachmentError = widget.attachmentError;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final tasks = await widget.repository.getRecentProjectTasks(widget.projectId, limit: 10);
      if (mounted) setState(() => _tasks = tasks);
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to load tasks: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('Added to ${widget.projectName}'),
      ),
      bottomNavigationBar: const VersionFooter(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: scheme.primary),
                const SizedBox(width: 8),
                Text('Task created', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
          if (widget.attachmentCount > 0) _buildAttachmentStatus(scheme),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'Last 10 open tasks in this project',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          Expanded(child: _buildList(scheme)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: widget.onDone,
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(ColorScheme scheme) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(_error!, style: TextStyle(color: scheme.error)),
        ),
      );
    }

    final tasks = _tasks;
    if (tasks == null) {
      // Optimistic view: show the newly-created task immediately,
      // and a loading placeholder for the rest.
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          _taskTile(scheme, widget.createdTaskTitle, isNew: true),
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        ],
      );
    }

    if (tasks.isEmpty) {
      return const Center(child: Text('No open tasks found in project.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final t = tasks[i];
        final isNew = t.id == widget.createdTaskId;
        return _taskTile(scheme, t.title, isNew: isNew);
      },
    );
  }

  Widget _buildAttachmentStatus(ColorScheme scheme) {
    final count = widget.attachmentCount;
    final err = _attachmentError;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(
            err == null ? Icons.attach_file : Icons.error_outline,
            size: 18,
            color: err == null ? scheme.primary : scheme.error,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              err == null
                  ? '$count attachment${count == 1 ? '' : 's'} uploaded'
                  : 'Attachment upload failed',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: err == null ? scheme.onSurface : scheme.error,
                  ),
            ),
          ),
          if (err != null && widget.retryAttachments != null)
            TextButton(
              onPressed: _isRetrying ? null : _retry,
              child: _isRetrying
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Retry'),
            ),
        ],
      ),
    );
  }

  Future<void> _retry() async {
    setState(() => _isRetrying = true);
    try {
      await widget.retryAttachments!();
      if (mounted) {
        setState(() {
          _attachmentError = null;
          _isRetrying = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _attachmentError = '$e';
          _isRetrying = false;
        });
      }
    }
  }

  Widget _taskTile(ColorScheme scheme, String title, {required bool isNew}) {
    return ListTile(
      leading: Icon(
        isNew ? Icons.fiber_new : Icons.circle_outlined,
        color: isNew ? scheme.primary : scheme.onSurfaceVariant,
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: isNew ? FontWeight.bold : FontWeight.normal),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
