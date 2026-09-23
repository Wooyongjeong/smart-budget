import 'package:flutter/material.dart';

class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.displayName,
  });

  final String eyebrow;
  final String title;
  final String displayName;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
            ],
          ),
        ),
        CircleAvatar(
          key: const ValueKey('profile-avatar'),
          radius: 24,
          backgroundColor: Theme.of(
            context,
          ).colorScheme.primary.withValues(alpha: 0.11),
          child: Text(
            _avatarInitial(displayName),
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );

  String _avatarInitial(String value) {
    final name = value.trim();
    return name.isEmpty ? '나' : String.fromCharCode(name.runes.first);
  }
}
