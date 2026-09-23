import 'package:flutter/material.dart';

import 'auth_service.dart';
import '../l10n/generated/app_localizations.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.service});
  final AuthService service;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool loading = false;
  String? error;

  Future<void> login() async {
    if (loading) return;
    setState(() {
      loading = true;
      error = null;
    });
    final result = await widget.service.signInWithKakao();
    if (!mounted) return;
    setState(() {
      loading = false;
      error = switch (result) {
        AuthStarted() => null,
        AuthCancelled() => AppLocalizations.of(context)!.loginCancelled,
        AuthFailed() => AppLocalizations.of(context)!.loginFailed,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.account_balance_wallet_outlined, size: 56),
                const SizedBox(height: 20),
                Text(
                  l10n.appTitle,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(l10n.loginTagline, textAlign: TextAlign.center),
                const SizedBox(height: 36),
                if (error != null) ...[
                  Text(
                    error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                FilledButton.icon(
                  onPressed: loading ? null : login,
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: Text(
                    loading ? l10n.loginLoading : l10n.loginWithKakao,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
