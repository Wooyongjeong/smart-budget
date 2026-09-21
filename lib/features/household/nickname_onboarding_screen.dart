import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import 'household_repository.dart';

class NicknameOnboardingScreen extends StatefulWidget {
  const NicknameOnboardingScreen({
    super.key,
    required this.repository,
    required this.initialName,
    required this.onComplete,
  });

  final HouseholdRepository repository;
  final String initialName;
  final ValueChanged<String> onComplete;

  @override
  State<NicknameOnboardingScreen> createState() =>
      _NicknameOnboardingScreenState();
}

class _NicknameOnboardingScreenState extends State<NicknameOnboardingScreen> {
  late final TextEditingController controller = TextEditingController(
    text: widget.initialName.trim().isEmpty ? '나' : widget.initialName.trim(),
  );
  bool busy = false;
  String? errorCode;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final name = controller.text.trim();
    if (name.isEmpty || name.length > 100) {
      setState(() => errorCode = 'invalid');
      return;
    }
    setState(() {
      busy = true;
      errorCode = null;
    });
    try {
      final savedName = await widget.repository.updateDisplayName(name);
      if (!mounted) return;
      widget.onComplete(savedName);
    } on HouseholdException catch (error) {
      if (mounted) setState(() => errorCode = error.code);
    } catch (_) {
      if (mounted) setState(() => errorCode = 'unexpected');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final error = switch (errorCode) {
      'invalid' || 'display_name_invalid' => l10n.nicknameInvalid,
      _ when errorCode != null => l10n.householdActionFailed,
      _ => null,
    };
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.badge_outlined, size: 56),
                  const SizedBox(height: 20),
                  Text(
                    l10n.nicknameOnboardingTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.nicknameOnboardingDescription,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    key: const ValueKey('onboarding-nickname'),
                    controller: controller,
                    maxLength: 100,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) {
                      if (!busy) save();
                    },
                    decoration: InputDecoration(
                      labelText: l10n.nickname,
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                      errorText: error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: busy ? null : save,
                    child: Text(l10n.nicknameSave),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
