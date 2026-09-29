import 'package:flutter/material.dart';

/// Help icon that shows a dialog with explanation text
class HelpIcon extends StatelessWidget {
  final String text;
  final double size;

  const HelpIcon({
    super.key,
    required this.text,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.help_outline, size: size, color: Colors.grey),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('说明'),
            content: Text(text),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('确定'),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Section header with optional help icon
class SectionHeaderWithHelp extends StatelessWidget {
  final String title;
  final String? helpText;

  const SectionHeaderWithHelp({
    super.key,
    required this.title,
    this.helpText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          if (helpText != null) ...[
            const SizedBox(width: 4),
            HelpIcon(text: helpText!),
          ],
        ],
      ),
    );
  }
}
