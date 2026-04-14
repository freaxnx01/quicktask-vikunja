import 'package:flutter/material.dart';
import '../models/project.dart';
import '../data/vikunja_repository.dart';
import '../data/title_fetcher.dart';
import '../data/project_usage_tracker.dart';
import '../data/task_history.dart';
import 'task_confirmation_screen.dart';

class ProjectPickerScreen extends StatefulWidget {
  final String sharedText;
  final String? extraSubject;
  final VikunjaRepository repository;
  final TitleFetcher titleFetcher;
  final ProjectUsageTracker usageTracker;
  final TaskHistory taskHistory;
  final VoidCallback onDone;

  const ProjectPickerScreen({
    super.key,
    required this.sharedText,
    this.extraSubject,
    required this.repository,
    required this.titleFetcher,
    required this.usageTracker,
    required this.taskHistory,
    required this.onDone,
  });

  @override
  State<ProjectPickerScreen> createState() => _ProjectPickerScreenState();
}

class _ProjectPickerScreenState extends State<ProjectPickerScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  ResolvedTask? _resolvedTask;
  List<Project> _allProjects = [];
  List<int> _recentIds = [];
  bool _isLoading = true;
  bool _isCreating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final results = await Future.wait([
        widget.titleFetcher.resolveTask(widget.sharedText, widget.extraSubject),
        widget.repository.getAllProjects(),
        widget.usageTracker.getRecentProjectIds(),
      ]);

      setState(() {
        _resolvedTask = results[0] as ResolvedTask;
        _allProjects = results[1] as List<Project>;
        _recentIds = results[2] as List<int>;
        _isLoading = false;
      });

      _focusNode.requestFocus();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load: $e';
      });
    }
  }

  List<Project> get _filteredProjects {
    final query = _searchController.text.toLowerCase();
    var projects = _allProjects;
    if (query.isNotEmpty) {
      projects = projects.where((p) => p.title.toLowerCase().contains(query)).toList();
    }
    return projects;
  }

  List<Project> get _recentProjects =>
      _filteredProjects.where((p) => _recentIds.contains(p.id)).toList();

  List<Project> get _otherProjects {
    final other = _filteredProjects.where((p) => !_recentIds.contains(p.id)).toList();
    other.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return other;
  }

  Future<void> _onProjectSelected(Project project) async {
    setState(() => _isCreating = true);
    final task = _resolvedTask!;

    try {
      final created = await widget.repository.createTask(
        project.id,
        task.title,
        description: task.url,
      );
      await widget.usageTracker.recordUsage(project.id);
      await widget.taskHistory.addEntry(TaskHistoryEntry(
        taskName: task.title,
        projectName: project.title,
        url: task.url,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ));

      if (mounted) {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => TaskConfirmationScreen(
              projectId: project.id,
              projectName: project.title,
              createdTaskId: created.id,
              createdTaskTitle: created.title,
              repository: widget.repository,
              onDone: widget.onDone,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCreating = false;
          _error = 'Failed to create task: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add to project')),
      body: Column(
        children: [
          // Task name preview
          if (_resolvedTask != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _resolvedTask!.title,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_resolvedTask!.url != null)
                    Text(
                      TitleFetcher.shortenUrl(_resolvedTask!.url!),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                ],
              ),
            ),
          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              decoration: const InputDecoration(
                hintText: 'Search projects...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          // Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _allProjects.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ),
      );
    }

    final recent = _recentProjects;
    final other = _otherProjects;

    return Stack(
      children: [
        ListView(
          children: [
            if (recent.isNotEmpty) ...[
              _sectionHeader('Recent'),
              ...recent.map((p) => _projectTile(p)),
            ],
            if (other.isNotEmpty) ...[
              _sectionHeader('All Projects'),
              ...other.map((p) => _projectTile(p)),
            ],
          ],
        ),
        if (_isCreating)
          const Center(child: CircularProgressIndicator()),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  Widget _projectTile(Project project) {
    return ListTile(
      title: Text(project.title),
      onTap: _isCreating ? null : () => _onProjectSelected(project),
    );
  }
}
