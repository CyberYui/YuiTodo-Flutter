import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/icons/app_icons.dart';
import '../../core/icons/flat_icon_mapper.dart';

/// Icon picker with lazy loading for 200+ icons
class IconPickerBottomSheet extends ConsumerStatefulWidget {
  final String? selectedIcon;
  final ValueChanged<String> onSelected;

  const IconPickerBottomSheet({
    super.key,
    required this.selectedIcon,
    required this.onSelected,
  });

  @override
  ConsumerState<IconPickerBottomSheet> createState() => _IconPickerBottomSheetState();
}

class _IconPickerBottomSheetState extends ConsumerState<IconPickerBottomSheet> {
  String _searchQuery = '';
  String _selectedCategory = 'all';
  final _searchController = TextEditingController();
  int _displayCount = 50; // Initial display count

  static const _categories = [
    {'id': 'all', 'name': '全部'},
    {'id': 'avatar', 'name': '二次元'},
    {'id': 'navigation', 'name': '导航'},
    {'id': 'notifications', 'name': '通知'},
    {'id': 'time', 'name': '时间'},
    {'id': 'files', 'name': '文件'},
    {'id': 'actions', 'name': '操作'},
    {'id': 'communication', 'name': '通讯'},
    {'id': 'media', 'name': '媒体'},
    {'id': 'weather', 'name': '天气'},
    {'id': 'food', 'name': '美食'},
    {'id': 'travel', 'name': '旅行'},
    {'id': 'objects', 'name': '物品'},
    {'id': 'symbols', 'name': '符号'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title and search
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('选择图标', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '搜索图标...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                  ),
                ],
              ),
            ),

            // Category tabs
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat['id'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(cat['name']!),
                      selected: isSelected,
                      onSelected: (_) => setState(() {
                        _selectedCategory = cat['id']!;
                        _displayCount = 50;
                      }),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // Icon grid
            Expanded(
              child: _buildIconGrid(context, scrollController),
            ),
          ],
        );
      },
    );
  }

  Widget _buildIconGrid(BuildContext context, ScrollController scrollController) {
    final icons = _getFilteredIcons();
    final displayIcons = icons.take(_displayCount).toList();
    final hasMore = icons.length > _displayCount;

    return CustomScrollView(
      controller: scrollController,
      slivers: [
        SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final iconName = displayIcons[index];
              final isSelected = widget.selectedIcon == iconName;
              final isAvatar = AppIcons.isAvatar(iconName);

              return GestureDetector(
                onTap: () => widget.onSelected(iconName),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : null,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                        : Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: isAvatar
                      ? Padding(
                          padding: const EdgeInsets.all(4),
                          child: Image.asset(
                            'assets/icons/$iconName.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(Icons.help_outline, color: Colors.grey),
                          ),
                        )
                      : Icon(
                          FlatIconMapper.getIcon(iconName),
                          size: 24,
                          color: isSelected ? Theme.of(context).colorScheme.primary : null,
                        ),
                ),
              );
            },
            childCount: displayIcons.length,
          ),
        ),
        if (hasMore)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _displayCount += 50),
                  icon: const Icon(Icons.expand_more),
                  label: Text('加载更多 (${icons.length - _displayCount})'),
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<String> _getFilteredIcons() {
    List<String> icons = [];
    
    if (_selectedCategory == 'all' || _selectedCategory == 'avatar') {
      for (final name in AppIcons.avatarNames) {
        if (_searchQuery.isEmpty || name.toLowerCase().contains(_searchQuery)) {
          icons.add(name);
        }
      }
    }
    
    if (_selectedCategory != 'avatar') {
      for (final icon in AppIcons.flatIcons) {
        if (_selectedCategory == 'all' || icon.category == _selectedCategory) {
          if (_searchQuery.isEmpty || icon.name.toLowerCase().contains(_searchQuery)) {
            icons.add(icon.name);
          }
        }
      }
    }
    
    return icons;
  }
}
