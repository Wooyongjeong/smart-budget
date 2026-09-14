import 'package:flutter/material.dart';

import 'auth_service.dart';

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
        AuthCancelled() => '로그인을 취소했어요.',
        AuthFailed(:final message) => message,
      };
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
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
              const Text(
                '우리 가계부',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              const Text('둘이 함께 기록하는 생활비', textAlign: TextAlign.center),
              const SizedBox(height: 36),
              if (error != null) ...[
                Text(
                  error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 16),
              ],
              FilledButton.icon(
                onPressed: loading ? null : login,
                icon: const Icon(Icons.chat_bubble_outline),
                label: Text(loading ? '카카오 로그인 준비 중…' : '카카오로 시작하기'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
