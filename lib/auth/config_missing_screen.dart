import 'package:flutter/material.dart';

class ConfigMissingScreen extends StatelessWidget {
  const ConfigMissingScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.settings_outlined, size: 56),
            SizedBox(height: 20),
            Text(
              '인증 설정이 필요해요',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              'Supabase와 카카오 로그인 설정 후 실행할 수 있어요.\n\nSUPABASE_URL\nSUPABASE_PUBLISHABLE_KEY\nAUTH_REDIRECT_URL\n\n세 값은 --dart-define으로 전달해 주세요.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}
