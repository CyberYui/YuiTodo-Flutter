import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../providers/tag_provider.dart';
import '../ui/screens/task_editor_screen.dart';
import '../ui/widgets/task_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _searchQuery = '';
  String _smartFilter = 'all';
  bool _showSearch = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Task> _filterTasks(List<Task> tasks) {
    var filtered = tasks;
    
    // Smart filter
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayEnd = today.add(const Duration(days: 1));
    final tomorrowEnd = today.add(const Duration(days: 2));

    switch (_smartFilter) {
      case 'today':
        filtered = filtered.where((t) {
          final date = DateTime.fromMillisecondsSinceEpoch(t.startDate ?? t.startTime ?? 0);
          return date.isAfter(today) && date.isBefore(todayEnd);
        }).toList();
        break;
      case 'tomorrow':
        filtered = filtered.where((t) {
          final date = DateTime.fromMillisecondsSinceEpoch(t.startDate ?? t.startTime ?? 0);
          return date.isAfter(todayEnd) && date.isBefore(tomorrowEnd);
        }).toList();
        break;
      case 'future':
        filtered = filtered.where((t) {
          final date = DateTime.fromMillisecondsSinceEpoch(t.startDate ?? t.startTime ?? 0);
          return date.isAfter(tomorrowEnd);
        }).toList();
        break;
      case 'completed':
        filtered = filtered.where((t) => t.status == 'done').toList();
        break;
    }

    // Search
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((t) {
        return t.title.toLowerCase().contains(query) || 
               t.note.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  void _openTaskEditor(Task? task) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaskEditorScreen(task: task)),
    );
  }

  void _enterSelectionMode(int taskId) {
    ref.read(selectionProvider.notifier).toggle(taskId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tasksAsync = ref.watch(taskListProvider);
    final selection = ref.watch(selectionProvider);
    final isSelectionMode = selection.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: '搜索任务...',
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              )
            : const Text('YuiTodo'),
        actions: [
          if (isSelectionMode) ...[
            Text('已选 ${selection.length}'),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                ref.read(taskListProvider.notifier).batchDelete(selection);
                ref.read(selectionProvider.notifier).clear();
              },
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => setState(() => _showSearch = !_showSearch),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Smart filter bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _filterChip('all', '全部'),
                const SizedBox(width: 8),
                _filterChip('today', '今天'),
                const SizedBox(width: 8),
                _filterChip('tomorrow', '明天'),
                const SizedBox(width: 8),
                _filterChip('future', '未来'),
                const SizedBox(width: 8),
                _filterChip('completed', '已完成'),
              ],
            ),
          ),
          // Task list
          Expanded(
            child: tasksAsync.when(
              data: (tasks) {
                final filtered = _filterTasks(tasks);
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.task_alt, size: 64, color: theme.colorScheme.outline),
                        const SizedBox(height: 16),
                        Text('暂无任务', style: TextStyle(color: theme.colorScheme.outline)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final task = filtered[index];
                    return TaskCard(
                      task: task,
                      isSelected: selection.contains(task.id),
                      onTap: () {
                        if (isSelectionMode) {
                          ref.read(selectionProvider.notifier).toggle(task.id!);
                        } else {
                          _openTaskEditor(task);
                        }
                      },
                      onLongPress: () => _enterSelectionMode(task.id!),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('加载失败: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openTaskEditor(null),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _filterChip(String id, String label) {
    final isSelected = _smartFilter == id;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _smartFilter = id),
    );
  }
}
