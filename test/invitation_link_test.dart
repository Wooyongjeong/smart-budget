import 'package:flutter_test/flutter_test.dart';
import 'package:smart_budget/features/household/invitation_link.dart';

void main() {
  const token = '0123456789abcdef0123456789abcdef0123456789abcdef';

  test('extracts invitation tokens from web and custom links', () {
    expect(
      invitationTokenFromUri(
        Uri.parse('https://smart-budget.app/invite/$token'),
        allowedWebHost: 'smart-budget.app',
      ),
      token,
    );
    expect(
      invitationTokenFromUri(
        Uri.parse('smartbudget://invite/$token'),
        allowedWebHost: 'smart-budget.app',
      ),
      token,
    );
  });

  test('rejects unrelated or malformed links', () {
    expect(
      invitationTokenFromUri(
        Uri.parse('https://smart-budget.app/'),
        allowedWebHost: 'smart-budget.app',
      ),
      isNull,
    );
    expect(
      invitationTokenFromUri(
        Uri.parse('smartbudget://login-callback/$token'),
        allowedWebHost: 'smart-budget.app',
      ),
      isNull,
    );
    expect(
      invitationTokenFromUri(
        Uri.parse('https://smart-budget.app/invite/short'),
        allowedWebHost: 'smart-budget.app',
      ),
      isNull,
    );
    expect(
      invitationTokenFromUri(
        Uri.parse('http://smart-budget.app/invite/$token'),
        allowedWebHost: 'smart-budget.app',
      ),
      isNull,
    );
    expect(
      invitationTokenFromUri(
        Uri.parse('https://phishing.example/invite/$token'),
        allowedWebHost: 'smart-budget.app',
      ),
      isNull,
    );
    expect(
      invitationTokenFromUri(
        Uri.parse('https://smart-budget.app/invite/${token.toUpperCase()}'),
        allowedWebHost: 'smart-budget.app',
      ),
      isNull,
    );
  });

  test('builds a normalized share link', () {
    expect(
      invitationLink('https://smart-budget.app/invite/', token),
      'https://smart-budget.app/invite/$token',
    );
  });
}
