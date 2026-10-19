import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Full plain-text licenses for the bundled open-source fonts.
///
/// The text is loaded from the bundled OFL files, so users do not need to
/// browse the repository or an `assets/` directory.
class FontLicensesScreen extends StatefulWidget {
  const FontLicensesScreen({super.key});

  @override
  State<FontLicensesScreen> createState() => _FontLicensesScreenState();
}

class _FontLicensesScreenState extends State<FontLicensesScreen> {
  late final Future<List<_FontLicense>> _licenses = _load();

  Future<List<_FontLicense>> _load() async {
    final items = <_FontLicense>[];
    for (final meta in _fontMeta) {
      items.add(
        _FontLicense(meta, await rootBundle.loadString(meta.asset)),
      );
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('开源字体许可')),
      body: FutureBuilder<List<_FontLicense>>(
        future: _licenses,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('许可文本加载失败：${snapshot.error}'));
          }
          final items = snapshot.data ?? const <_FontLicense>[];
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: items.length + 1,
            separatorBuilder: (context, index) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Text(
                  '以下字体均以 SIL Open Font License 1.1 授权，仅用于界面显示。'
                  '完整许可明文如下，可长按选择或复制。',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                    height: 1.5,
                  ),
                );
              }
              final item = items[index - 1];
              return Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.meta.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.meta.owner,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      const Divider(height: 24),
                      SelectableText(
                        item.text,
                        style: theme.textTheme.bodySmall?.copyWith(
                          height: 1.55,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _FontMeta {
  final String name;
  final String owner;
  final String asset;

  const _FontMeta(this.name, this.owner, this.asset);
}

class _FontLicense {
  final _FontMeta meta;
  final String text;

  const _FontLicense(this.meta, this.text);
}

const List<_FontMeta> _fontMeta = <_FontMeta>[
  _FontMeta(
    '思源黑体 Source Han Sans SC',
    'Adobe · SIL OFL 1.1',
    'assets/fonts/open/OFL-SourceHanSans.txt',
  ),
  _FontMeta(
    '得意黑 Smiley Sans',
    'atelier-anchor · SIL OFL 1.1',
    'assets/fonts/open/OFL-SmileySans.txt',
  ),
  _FontMeta(
    '霞鹜文楷 Lite LXGW WenKai Lite',
    'LXGW · SIL OFL 1.1',
    'assets/fonts/open/OFL-LXGWWenKai.txt',
  ),
  _FontMeta(
    'IBM Plex Sans SC / IBM Plex Mono',
    'IBM · SIL OFL 1.1',
    'assets/fonts/open/OFL-IBMPlex.txt',
  ),
];
