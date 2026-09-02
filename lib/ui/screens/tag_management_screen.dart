import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/task.dart';
import '../../providers/tag_provider.dart';
import '../../core/theme/task_colors.dart';

class TagManagementScreen extends ConsumerStatefulWidget {
  const TagManagementScreen({super.key});

  @override
  ConsumerState<TagManagementScreen> createState() => _TagManagementScreenState();
}

class _TagManagementScreenState extends ConsumerState<TagManagementScreen> {
  final _nameController = TextEditingController();
  String _selectedColor = '#3B82F6';

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addTag() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    ref.read(tagListProvider.notifier).addTag(Tag(
      name: name,
      color: _selectedColor,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));
    _nameController.clear();
  }

  void _showColorPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('选择标签颜色', style: Theme.of(context).textTheme.titleLarge),
            ),
            // Quick colors
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: TaskColors.all.map((c) {
                  final isSelected = _selectedColor == c;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedColor = c;
                      Navigator.pop(context);
                    }),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Color(int.parse(c.replaceFirst('#', '0xFF'))),
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            // Custom color button
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showCustomColorPicker();
              },
              icon: const Icon(Icons.color_lens),
              label: const Text('自定义颜色'),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  void _showCustomColorPicker() {
    showDialog(
      context: context,
      builder: (context) {
        Color currentColor = TaskColors.colorFromHex(_selectedColor);
        return AlertDialog(
          title: const Text('自定义颜色'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // RGB Sliders
              StatefulBuilder(
                builder: (context, setDialogState) {
                  return Column(
                    children: [
                      // Red
                      Row(
                        children: [
                          const Text('R'),
                          Expanded(
                            child: Slider(
                              value: currentColor.red.toDouble(),
                              min: 0,
                              max: 255,
                              activeColor: Colors.red,
                              onChanged: (v) {
                                setDialogState(() {
                                  currentColor = Color.fromARGB(255, v.round(), currentColor.green, currentColor.blue);
                                });
                              },
                            ),
                          ),
                          Text('${currentColor.red}'),
                        ],
                      ),
                      // Green
                      Row(
                        children: [
                          const Text('G'),
                          Expanded(
                            child: Slider(
                              value: currentColor.green.toDouble(),
                              min: 0,
                              max: 255,
                              activeColor: Colors.green,
                              onChanged: (v) {
                                setDialogState(() {
                                  currentColor = Color.fromARGB(255, currentColor.red, v.round(), currentColor.blue);
                                });
                              },
                            ),
                          ),
                          Text('${currentColor.green}'),
                        ],
                      ),
                      // Blue
                      Row(
                        children: [
                          const Text('B'),
                          Expanded(
                            child: Slider(
                              value: currentColor.blue.toDouble(),
                              min: 0,
                              max: 255,
                              activeColor: Colors.blue,
                              onChanged: (v) {
                                setDialogState(() {
                                  currentColor = Color.fromARGB(255, currentColor.red, currentColor.green, v.round());
                                });
                              },
                            ),
                          ),
                          Text('${currentColor.blue}'),
                        ],
                      ),
                      // Preview
                      Container(
                        width: double.infinity,
                        height: 50,
                        margin: const EdgeInsets.only(top: 16),
                        decoration: BoxDecoration(
                          color: currentColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                final hex = '#${currentColor.value.toRadixString(16).substring(2).toUpperCase()}';
                setState(() => _selectedColor = hex);
                Navigator.pop(context);
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tagsAsync = ref.watch(tagListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('管理标签'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: '新标签名称',
                        ),
                        onSubmitted: (_) => _addTag(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _addTag,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Color preview and picker
                GestureDetector(
                  onTap: _showColorPicker,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Color(int.parse(_selectedColor.replaceFirst('#', '0xFF'))),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text('标签颜色: $_selectedColor'),
                        ),
                        const Icon(Icons.palette, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: tagsAsync.when(
              data: (tags) => ListView.builder(
                itemCount: tags.length,
                itemBuilder: (context, index) {
                  final tag = tags[index];
                  return ListTile(
                    leading: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Color(int.parse(tag.color.replaceFirst('#', '0xFF'))),
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(
                      tag.name,
                      style: TextStyle(
                        color: Color(int.parse(tag.color.replaceFirst('#', '0xFF'))),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => ref.read(tagListProvider.notifier).deleteTag(tag.id!),
                    ),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('加载失败: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
