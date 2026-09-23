const invitationTokenLength = 48;

bool isInvitationToken(String value) =>
    RegExp(r'^[0-9a-f]{48}$').hasMatch(value);

String? invitationTokenFromInput(
  String value, {
  required String allowedWebHost,
}) {
  final input = value.trim();
  if (isInvitationToken(input)) return input;
  final uri = Uri.tryParse(input);
  if (uri == null) return null;
  return invitationTokenFromUri(uri, allowedWebHost: allowedWebHost);
}

String? invitationTokenFromUri(Uri uri, {required String allowedWebHost}) {
  final isSupportedScheme = uri.scheme == 'smartbudget';
  final isSupportedWebLink =
      uri.scheme == 'https' &&
      uri.host == allowedWebHost &&
      uri.pathSegments.length == 2 &&
      uri.pathSegments.first == 'invite';
  if (!isSupportedScheme && !isSupportedWebLink) return null;

  final token = isSupportedScheme
      ? (uri.host == 'invite' && uri.pathSegments.length == 1
            ? uri.pathSegments.single
            : null)
      : uri.pathSegments.last;
  if (token == null || !isInvitationToken(token)) {
    return null;
  }
  return token;
}

String invitationLink(String baseUrl, String token) {
  final base = baseUrl.endsWith('/')
      ? baseUrl.substring(0, baseUrl.length - 1)
      : baseUrl;
  return '$base/$token';
}
