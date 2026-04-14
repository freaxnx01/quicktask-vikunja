import 'package:flutter/material.dart';
import '../models/project.dart';
import '../models/shared_content.dart';
import '../data/vikunja_repository.dart';
import '../data/title_fetcher.dart';
import '../data/project_usage_tracker.dart';
import '../data/task_history.dart';
import 'task_confirmation_screen.dart';

class ProjectPickerScreen extends StatefulWidget {
  final SharedContent shared;
  final VikunjaRepository repository;
  final TitleFetcher titleFetcher;
  final ProjectUsageTracker usageTracker;
  final TaskHistory taskHistory;
  final VoidCallback onDone;

  const ProjectPickerScreen({
    super.key,
    required this.shared,
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
  final _titleController = TextEditingController();
  final _focusNode = FocusNode();

  String? _resolvedUrl;
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
      final futures = <Future>[
        widget.repository.getAllProjects(),
        widget.usageTracker.getRecentProjectIds(),
      ];
      // Only resolve URL title for text-only shares.
      if (widget.shared.hasText && !widget.shared.hasFiles) {
        futures.add(widget.titleFetcher.resolveTask(
          widget.shared.text!,
          widget.shared.extraSubject,
        ));
      }
      final results = await Future.wait(futures);

      _allProjects = results[0] as List<Project>;
      _recentIds = results[1] as List<int>;

      String initialTitle;
      if (results.length > 2) {
        final resolved = results[2] as ResolvedTask;
        initialTitle = resolved.title;
        _resolvedUrl = resolved.url;
      } else if (widget.shared.hasFiles) {
        initialTitle = widget.shared.files.map((f) => f.name).join(' + ');
      } else {
        initialTitle = widget.shared.text ?? '';
      }
      _titleController.text = initialTitle;

      setState(() => _isLoading = false);
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
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Task title cannot be empty');
      return;
    }
    setState(() => _isCreating = true);

    try {
      final created = await widget.repository.createTask(
        project.id,
        title,
        description: _resolvedUrl,
      );
      await widget.usageTracker.recordUsage(project.id);
      await widget.taskHistory.addEntry(TaskHistoryEntry(
        taskName: title,
        projectName: project.title,
        url: _resolvedUrl,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ));

      final filePaths = widget.shared.files.map((f) => f.path).toList();
      String? attachmentError;
      if (filePaths.isNotEmpty) {
        try {
          await widget.repository.uploadAttachments(created.id, filePaths);
        } catch (e) {
          attachmentError = '$e';
        }
      }

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
              attachmentCount: filePaths.length,
              attachmentError: attachmentError,
              retryAttachments: attachmentError == null
                  ? null
                  : () => widget.repository.uploadAttachments(created.id, filePaths),
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
    _titleController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add to project')),
      body: Column(
        children: [
          // Title (editable) + optional URL + file chips
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleController,
                    maxLines: 2,
                    minLines: 1,
                    decoration: const InputDecoration(
                      labelText: 'Task title',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  if (_resolvedUrl != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      TitleFetcher.shortenUrl(_resolvedUrl!),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                  if (widget.shared.hasFiles) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: widget.shared.files
                          .map((f) => Chip(
                                avatar: const Icon(Icons.attach_file, size: 16),
                                label: Text(f.name, overflow: TextOverflow.ellipsis),
                                visualDensity: VisualDensity.compact,
                              ))
                          .toList(),
                    ),
                  ],
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
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
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
