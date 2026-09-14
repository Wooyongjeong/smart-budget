class SupabaseConfig {
  const SupabaseConfig({
    required this.url,
    required this.publishableKey,
    required this.redirectUrl,
  });

  final String url;
  final String publishableKey;
  final String redirectUrl;

  bool get isConfigured =>
      url.startsWith('https://') &&
      publishableKey.isNotEmpty &&
      redirectUrl.isNotEmpty;

  factory SupabaseConfig.fromEnvironment() => const SupabaseConfig(
    url: String.fromEnvironment('SUPABASE_URL'),
    publishableKey: String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
    redirectUrl: String.fromEnvironment('AUTH_REDIRECT_URL'),
  );
}
