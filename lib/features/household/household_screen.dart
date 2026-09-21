import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/generated/app_localizations.dart';
import 'household_repository.dart';
import 'invitation_link.dart';

class HouseholdScreen extends StatefulWidget {
  const HouseholdScreen({
    super.key,
    required this.repository,
    required this.onLeft,
    this.onHouseholdChanged,
    this.invitationLinkBaseUrl = 'https://smart-budget.app/invite',
  });

  final HouseholdRepository repository;
  final Future<void> Function() onLeft;
  final ValueChanged<String>? onHouseholdChanged;
  final String invitationLinkBaseUrl;

  @override
  State<HouseholdScreen> createState() => _HouseholdScreenState();
}

class _HouseholdScreenState extends State<HouseholdScreen> {
  final tokenController = TextEditingController();
  late Future<HouseholdOverview> overview = widget.repository.load();
  String? invitation;
  bool busy = false;

  @override
  void dispose() {
    tokenController.dispose();
    super.dispose();
  }

  void reload() => setState(() => overview = widget.repository.load());

  Future<void> createInvitation(HouseholdOverview household) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final token = await widget.repository.createInvitation(household.id);
      if (mounted) {
        setState(
          () =>
              invitation = invitationLink(widget.invitationLinkBaseUrl, token),
        );
      }
    } on HouseholdException catch (error) {
      if (mounted) _showError(error.code);
    } catch (_) {
      if (mounted) _showError('unexpected');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> acceptInvitation() async {
    if (busy) return;
    final token = tokenController.text.trim();
    if (token.length != 48) {
      _showError('invitation_invalid');
      return;
    }
    setState(() => busy = true);
    try {
      final householdId = await widget.repository.acceptInvitation(token);
      widget.onHouseholdChanged?.call(householdId);
      tokenController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.invitationAccepted),
        ),
      );
      reload();
    } on HouseholdException catch (error) {
      if (mounted) _showError(error.code);
    } catch (_) {
      if (mounted) _showError('unexpected');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> confirmLeave(HouseholdOverview household) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.leaveHouseholdTitle),
        content: Text(l10n.leaveHouseholdBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.leaveHousehold),
          ),
        ],
      ),
    );
    if (confirmed != true || busy) return;
    setState(() => busy = true);
    try {
      await widget.repository.leave(household.id);
      await widget.onLeft();
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
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
      appBar: AppBar(title: Text(l10n.sharedHousehold)),
      body: FutureBuilder<HouseholdOverview>(
        future: overview,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: TextButton(onPressed: reload, child: Text(l10n.retry)),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final household = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            children: [
              Text(
                household.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(l10n.householdMembersCount(household.members.length)),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: household.members
                      .map(
                        (member) => ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person_outline),
                          ),
                          title: Text(member.name),
                          trailing: member.isMe ? Text(l10n.me) : null,
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.invitePartner,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(l10n.invitationDescription),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: busy || household.members.length >= 2
                    ? null
                    : () => createInvitation(household),
                icon: const Icon(Icons.link_rounded),
                label: Text(l10n.createInvitation),
              ),
              if (invitation != null) ...[
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    title: SelectableText(invitation!),
                    subtitle: Text(l10n.invitationExpires),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: l10n.shareInvitation,
                          onPressed: () async {
                            await SharePlus.instance.share(
                              ShareParams(text: invitation!),
                            );
                          },
                          icon: const Icon(Icons.ios_share_rounded),
                        ),
                        IconButton(
                          tooltip: l10n.copyInvitation,
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: invitation!),
                            );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.invitationCopied)),
                            );
                          },
                          icon: const Icon(Icons.copy_rounded),
                        ),
                      ],
                    ),
                    onTap: () async {
                      await SharePlus.instance.share(
                        ShareParams(text: invitation!),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 28),
              Text(
                l10n.joinHousehold,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('invitation-token'),
                controller: tokenController,
                maxLength: 48,
                autocorrect: false,
                decoration: InputDecoration(labelText: l10n.invitationCode),
              ),
              FilledButton.tonal(
                onPressed: busy ? null : acceptInvitation,
                child: Text(l10n.acceptInvitation),
              ),
              const SizedBox(height: 36),
              const Divider(),
              TextButton(
                key: const ValueKey('leave-household'),
                onPressed: busy ? null : () => confirmLeave(household),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: Text(l10n.leaveHousehold),
              ),
            ],
          );
        },
      ),
    );
  }
}
