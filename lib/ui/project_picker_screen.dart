import 'package:flutter/material.dart';
import '../models/project.dart';
import '../models/shared_content.dart';
import '../data/vikunja_repository.dart';
import '../data/title_fetcher.dart';
import '../data/project_usage_tracker.dart';
import '../data/project_favorites.dart';
import '../data/task_history.dart';
import 'task_confirmation_screen.dart';
import 'widgets/version_footer.dart';

class ProjectPickerScreen extends StatefulWidget {
  final SharedContent shared;
  final VikunjaRepository repository;
  final TitleFetcher titleFetcher;
  final ProjectUsageTracker usageTracker;
  final ProjectFavorites? favorites;
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
    this.favorites,
  });

  @override
  State<ProjectPickerScreen> createState() => _ProjectPickerScreenState();
}

class _ProjectPickerScreenState extends State<ProjectPickerScreen> {
  final _searchController = TextEditingController();
  final _titleController = TextEditingController();
  final _focusNode = FocusNode();

  late final ProjectFavorites _favorites =
      widget.favorites ?? ProjectFavorites();

  String? _resolvedUrl;
  List<Project> _allProjects = [];
  List<int> _recentIds = [];
  Set<int> _favoriteIds = <int>{};
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
        _favorites.getFavoriteIds(),
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
      _favoriteIds = results[2] as Set<int>;

      String initialTitle;
      if (results.length > 3) {
        final resolved = results[3] as ResolvedTask;
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
      projects =
          projects.where((p) => p.title.toLowerCase().contains(query)).toList();
    }
    return projects;
  }

  List<Project> get _favoriteProjects {
    final favorites =
        _filteredProjects.where((p) => _favoriteIds.contains(p.id)).toList();
    favorites
        .sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return favorites;
  }

  List<Project> get _recentProjects => _filteredProjects
      .where((p) => !_favoriteIds.contains(p.id) && _recentIds.contains(p.id))
      .toList();

  List<Project> get _otherProjects {
    final other = _filteredProjects
        .where(
            (p) => !_favoriteIds.contains(p.id) && !_recentIds.contains(p.id))
        .toList();
    other
        .sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return other;
  }

  Future<void> _toggleFavorite(Project project) async {
    await _favorites.toggle(project.id);
    if (!mounted) return;
    setState(() {
      if (!_favoriteIds.add(project.id)) {
        _favoriteIds.remove(project.id);
      }
    });
  }

  Future<void> _onProjectSelected(Project project) async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Task title cannot be empty');
      return;
    }

    final lines = title
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.length > 20) {
      await _showTooManyLinesWarning();
      return;
    }
    if (lines.length >= 2) {
      final useBatch = await _showBatchChoiceDialog(lines.length);
      if (useBatch == null) return;
      if (useBatch) {
        await _runBatchFlow(project, lines);
        return;
      }
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
                  : () => widget.repository
                      .uploadAttachments(created.id, filePaths),
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

  Future<bool?> _showBatchChoiceDialog(int count) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$count lines detected'),
        content: const Text('How would you like to create this?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep as single task'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Create $count separate tasks'),
          ),
        ],
      ),
    );
  }

  Future<void> _showTooManyLinesWarning() {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Too many lines'),
        content: const Text(
          'Batch mode supports up to 20 lines. Please trim your input.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _runBatchFlow(Project project, List<String> lines) async {
    setState(() => _isCreating = true);
    final createdTitles = <String>[];
    try {
      final resolved = await Future.wait(
        lines.map((l) => widget.titleFetcher.resolveTask(l, null)),
      );

      for (final task in resolved) {
        final created = await widget.repository.createTask(
          project.id,
          task.title,
          description: task.url,
        );
        await widget.taskHistory.addEntry(TaskHistoryEntry(
          taskName: task.title,
          projectName: project.title,
          url: task.url,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ));
        createdTitles.add(created.title);
      }
      await widget.usageTracker.recordUsage(project.id);

      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => TaskConfirmationScreen(
            projectId: project.id,
            projectName: project.title,
            createdTaskId: 0,
            createdTaskTitle: '',
            repository: widget.repository,
            onDone: widget.onDone,
            batchResults: createdTitles,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCreating = false;
          _error = createdTitles.isEmpty
              ? 'Failed to create tasks: $e'
              : 'Failed after creating ${createdTitles.length} of ${lines.length} tasks: $e';
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
      bottomNavigationBar: const VersionFooter(),
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
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
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
                                label: Text(f.name,
                                    overflow: TextOverflow.ellipsis),
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
          child: Text(_error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ),
      );
    }

    final favorites = _favoriteProjects;
    final recent = _recentProjects;
    final other = _otherProjects;

    return Stack(
      children: [
        ListView(
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            if (favorites.isNotEmpty) ...[
              _sectionHeader('Favorites'),
              ...favorites.map((p) => _projectTile(p)),
            ],
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
        if (_isCreating) const Center(child: CircularProgressIndicator()),
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
    final isFavorite = _favoriteIds.contains(project.id);
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      title: Text(project.title),
      trailing: IconButton(
        icon: Icon(
          isFavorite ? Icons.star : Icons.star_border,
          color: isFavorite ? colors.primary : colors.onSurfaceVariant,
        ),
        tooltip: isFavorite ? 'Unfavorite' : 'Favorite',
        onPressed: _isCreating ? null : () => _toggleFavorite(project),
      ),
      onTap: _isCreating ? null : () => _onProjectSelected(project),
    );
  }
}
