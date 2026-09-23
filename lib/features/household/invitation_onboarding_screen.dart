import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import 'household_repository.dart';
import 'invitation_link.dart';

class InvitationOnboardingScreen extends StatefulWidget {
  const InvitationOnboardingScreen({
    super.key,
    required this.repository,
    this.initialToken,
    this.invitationLinkBaseUrl = 'https://smart-budget.app/invite',
    this.onAccepted,
    required this.onComplete,
  });

  final HouseholdRepository repository;
  final String? initialToken;
  final String invitationLinkBaseUrl;
  final ValueChanged<String>? onAccepted;
  final VoidCallback onComplete;

  @override
  State<InvitationOnboardingScreen> createState() =>
      _InvitationOnboardingScreenState();
}

class _InvitationOnboardingScreenState
    extends State<InvitationOnboardingScreen> {
  late final TextEditingController controller = TextEditingController(
    text: widget.initialToken,
  );
  bool busy = false;

  @override
  void didUpdateWidget(covariant InvitationOnboardingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextToken = widget.initialToken;
    if (nextToken != null && nextToken != oldWidget.initialToken) {
      controller.text = nextToken;
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> accept() async {
    final token = invitationTokenFromInput(
      controller.text,
      allowedWebHost: Uri.parse(widget.invitationLinkBaseUrl).host,
    );
    if (token == null) {
      _showError('invitation_invalid');
      return;
    }
    setState(() => busy = true);
    try {
      final householdId = await widget.repository.acceptInvitation(token);
      widget.onAccepted?.call(householdId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.invitationAccepted),
        ),
      );
      widget.onComplete();
    } on HouseholdException catch (error) {
      if (mounted) _showError(error.code);
    } catch (_) {
      if (mounted) _showError('unexpected');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void _showError(String code) {
    final l10n = AppLocalizations.of(context)!;
    final message = switch (code) {
      'invitation_invalid' => l10n.invitationInvalid,
      'invitation_expired_or_used' => l10n.invitationExpiredOrUsed,
      'already_member' => l10n.alreadyHouseholdMember,
      'household_full' => l10n.householdFull,
      'household_unavailable' => l10n.householdUnavailable,
      'forbidden' => l10n.householdForbidden,
      _ => l10n.householdActionFailed,
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                  const Icon(Icons.people_alt_outlined, size: 56),
                  const SizedBox(height: 20),
                  Text(
                    l10n.invitationOnboardingTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.invitationOnboardingDescription,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    key: const ValueKey('onboarding-invitation-token'),
                    controller: controller,
                    maxLength: 200,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: l10n.invitationCode,
                      prefixIcon: const Icon(Icons.link_rounded),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: busy ? null : accept,
                    child: Text(l10n.acceptInvitation),
                  ),
                  TextButton(
                    onPressed: busy ? null : widget.onComplete,
                    child: Text(l10n.skipInvitation),
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
