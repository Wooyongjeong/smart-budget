class SupabaseConfig {
  const SupabaseConfig({
    required this.url,
    required this.publishableKey,
    required this.redirectUrl,
    this.invitationLinkBaseUrl = 'https://smart-budget.app/invite',
  });

  final String url;
  final String publishableKey;
  final String redirectUrl;
  final String invitationLinkBaseUrl;

  bool get isConfigured =>
      url.startsWith('https://') &&
      publishableKey.isNotEmpty &&
      redirectUrl.isNotEmpty;

  factory SupabaseConfig.fromEnvironment() => const SupabaseConfig(
    url: String.fromEnvironment('SUPABASE_URL'),
    publishableKey: String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
    redirectUrl: String.fromEnvironment('AUTH_REDIRECT_URL'),
    invitationLinkBaseUrl: String.fromEnvironment(
      'INVITATION_LINK_BASE_URL',
      defaultValue: 'https://smart-budget.app/invite',
    ),
  );
}
