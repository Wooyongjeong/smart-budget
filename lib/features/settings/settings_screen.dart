import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../themes.dart';
import '../shared/app_page_header.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.displayName,
    required this.palettes,
    required this.selectedPalette,
    required this.saving,
    required this.onPaletteSelected,
    required this.localeCode,
    required this.onLocaleSelected,
    required this.hasHouseholdRepository,
    required this.onOpenHousehold,
    required this.canSignOut,
    required this.signingOut,
    required this.onSignOut,
  });

  final String displayName;
  final List<BudgetPalette> palettes;
  final BudgetPalette selectedPalette;
  final bool saving;
  final ValueChanged<BudgetPalette> onPaletteSelected;
  final String localeCode;
  final ValueChanged<String> onLocaleSelected;
  final bool hasHouseholdRepository;
  final ValueChanged<BuildContext> onOpenHousehold;
  final bool canSignOut;
  final bool signingOut;
  final ValueChanged<BuildContext> onSignOut;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 124),
      children: [
        AppPageHeader(
          eyebrow: l10n.settings,
          title: l10n.settings,
          displayName: displayName,
        ),
        const SizedBox(height: 16),
        Text(
          l10n.profileSection,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.person_outline_rounded),
            title: Text(displayName),
            subtitle: Text(l10n.displayName),
            trailing: hasHouseholdRepository
                ? const Icon(Icons.chevron_right_rounded)
                : null,
            onTap: hasHouseholdRepository
                ? () => onOpenHousehold(context)
                : null,
          ),
        ),
        const SizedBox(height: 24),
        Text(l10n.screenSection, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(l10n.themeDescription),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: palettes
              .map(
                (option) => Semantics(
                  selected: option == selectedPalette,
                  child: ChoiceChip(
                    key: ValueKey('theme-${option.id}'),
                    selected: option == selectedPalette,
                    showCheckmark: false,
                    onSelected: saving
                        ? null
                        : (_) => onPaletteSelected(option),
                    visualDensity: VisualDensity.compact,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...[
                          option.primary,
                          option.secondary,
                          option.background,
                        ].map(
                          (color) => Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.only(right: 2),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(_paletteName(l10n, option.id)),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.languageTitle,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(l10n.languageDescription),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'ko', label: Text(l10n.korean)),
            ButtonSegment(value: 'en', label: Text(l10n.english)),
          ],
          selected: {localeCode},
          onSelectionChanged: (value) => onLocaleSelected(value.first),
        ),
        const SizedBox(height: 28),
        Text(
          l10n.accountHousehold,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (!hasHouseholdRepository)
          Text(l10n.accountComingSoon)
        else
          Card(
            child: ListTile(
              leading: const Icon(Icons.people_outline_rounded),
              title: Text(l10n.sharedHousehold),
              subtitle: Text(l10n.manageHouseholdDescription),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => onOpenHousehold(context),
            ),
          ),
        if (canSignOut) ...[
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              key: const ValueKey('sign-out'),
              leading: Icon(
                Icons.logout_rounded,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(l10n.signOut),
              subtitle: Text(l10n.signOutDescription),
              trailing: signingOut
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chevron_right_rounded),
              enabled: !signingOut,
              onTap: () => onSignOut(context),
            ),
          ),
        ],
      ],
    );
  }

  String _paletteName(AppLocalizations l10n, String id) => switch (id) {
    'forest' => l10n.themeForest,
    'ocean' => l10n.themeOcean,
    'lavender' => l10n.themeLavender,
    'rose' => l10n.themeRose,
    'olive' => l10n.themeOlive,
    'terracotta' => l10n.themeTerracotta,
    'lemon' => l10n.themeLemon,
    'mint' => l10n.themeMint,
    'cocoa' => l10n.themeCocoa,
    'indigo' => l10n.themeIndigo,
    'plum' => l10n.themePlum,
    'sky' => l10n.themeSky,
    _ => id,
  };
}
