import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/task.dart';
import '../../repositories/task_repository.dart';
import 'task_editor_screen.dart';

/// Searches every task (all dates, completed included), not just the visible
/// occurrence list on the home screen.
class GlobalSearchScreen extends ConsumerStatefulWidget {
  final String? initialQuery;

  const GlobalSearchScreen({super.key, this.initialQuery});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  late final TextEditingController _controller;
  Timer? _debounce;
  List<Task> _results = const <Task>[];
  bool _loading = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery ?? '');
    _query = widget.initialQuery?.trim() ?? '';
    if (_query.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _runSearch(_query));
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _query = value.trim();
    _debounce?.cancel();
    if (_query.isEmpty) {
      setState(() {
        _results = const <Task>[];
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 250), () {
      _runSearch(_query);
    });
  }

  Future<void> _runSearch(String query) async {
    if (query.isEmpty) return;
    final results =
        await ref.read(taskRepositoryProvider).searchTasks(query);
    if (!mounted || query != _query) return;
    setState(() {
      _results = results;
      _loading = false;
    });
  }

  Future<void> _openTask(Task task) async {
    final repo = ref.read(taskRepositoryProvider);
    final full = task.id == null ? null : await repo.getTaskById(task.id!);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskEditorScreen(task: full ?? task),
      ),
    );
    if (!mounted) return;
    await _runSearch(_query);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: '搜索标题、备注、子任务或标签…',
            border: InputBorder.none,
          ),
          onChanged: _onChanged,
          onSubmitted: (value) {
            _debounce?.cancel();
            _query = value.trim();
            setState(() => _loading = _query.isNotEmpty);
            _runSearch(_query);
          },
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: '清空',
              onPressed: () {
                _controller.clear();
                _onChanged('');
              },
            ),
        ],
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_query.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            '搜索全部任务\n标题、备注、子任务或标签',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
              height: 1.6,
            ),
          ),
        ),
      );
    }
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_results.isEmpty) {
      return Center(
        child: Text(
          '没有找到匹配的任务',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 24),
      itemCount: _results.length,
      separatorBuilder: (context, index) => const SizedBox(height: 2),
      itemBuilder: (context, index) => _resultTile(_results[index], theme),
    );
  }

  Widget _resultTile(Task task, ThemeData theme) {
    final color = Color(int.parse(task.color.replaceFirst('#', '0xFF')));
    final done = task.status == 'done';
    final date = DateTime.fromMillisecondsSinceEpoch(
      task.startDate ?? task.startTime ?? task.createdAt,
    );
    final note = task.note.trim();
    final dateLabel =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      leading: Icon(
        done ? Icons.check_circle : Icons.radio_button_unchecked,
        color: done ? color : theme.colorScheme.outline,
      ),
      title: Text(
        task.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        note.isEmpty ? dateLabel : '$dateLabel · $note',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        done ? '已完成' : '待办',
        style: theme.textTheme.bodySmall?.copyWith(
          color: done ? color : theme.colorScheme.outline,
        ),
      ),
      onTap: () => _openTask(task),
    );
  }
}
