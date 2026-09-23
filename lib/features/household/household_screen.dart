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
    this.onDisplayNameChanged,
    this.invitationLinkBaseUrl = 'https://smart-budget.app/invite',
  });

  final HouseholdRepository repository;
  final Future<void> Function() onLeft;
  final ValueChanged<String>? onHouseholdChanged;
  final ValueChanged<String>? onDisplayNameChanged;
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

  void reload() {
    setState(() {
      overview = widget.repository.load();
    });
  }

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
    final parsedToken = invitationTokenFromInput(
      token,
      allowedWebHost: Uri.parse(widget.invitationLinkBaseUrl).host,
    );
    if (parsedToken == null) {
      _showError('invitation_invalid');
      return;
    }
    setState(() => busy = true);
    try {
      final householdId = await widget.repository.acceptInvitation(parsedToken);
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

  Future<void> editDisplayName(HouseholdMember member) async {
    final controller = TextEditingController(text: member.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.editDisplayName),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 100,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.displayName,
          ),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
    if (name == null || name.trim().isEmpty || busy) return;
    setState(() => busy = true);
    String savedName;
    try {
      savedName = await widget.repository.updateDisplayName(name);
    } on HouseholdException catch (error) {
      if (mounted) _showError(error.code);
      return;
    } catch (_) {
      if (mounted) _showError('unexpected');
      return;
    } finally {
      if (mounted) setState(() => busy = false);
    }
    if (!mounted) return;
    reload();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onDisplayNameChanged?.call(savedName);
    });
  }

  Future<void> shareInvitation(BuildContext context, String value) async {
    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;
    await SharePlus.instance.share(
      ShareParams(text: value, sharePositionOrigin: origin),
    );
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
      'display_name_invalid' => l10n.displayNameInvalid,
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
                          trailing: member.isMe
                              ? IconButton(
                                  key: const ValueKey('edit-display-name'),
                                  tooltip: l10n.editDisplayName,
                                  onPressed: busy
                                      ? null
                                      : () => editDisplayName(member),
                                  icon: const Icon(Icons.edit_outlined),
                                )
                              : null,
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
                          onPressed: () =>
                              shareInvitation(context, invitation!),
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
                    onTap: () => shareInvitation(context, invitation!),
                  ),
                ),
              ],
              if (!household.members.any((member) => member.isMe)) ...[
                const SizedBox(height: 28),
                Text(
                  l10n.joinHousehold,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey('invitation-token'),
                  controller: tokenController,
                  maxLength: 200,
                  autocorrect: false,
                  decoration: InputDecoration(labelText: l10n.invitationCode),
                ),
                FilledButton.tonal(
                  onPressed: busy ? null : acceptInvitation,
                  child: Text(l10n.acceptInvitation),
                ),
              ],
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
