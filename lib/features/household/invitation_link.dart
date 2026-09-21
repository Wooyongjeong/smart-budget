const invitationTokenLength = 48;

String? invitationTokenFromUri(Uri uri) {
  final isSupportedScheme = uri.scheme == 'smartbudget';
  final isSupportedWebLink =
      (uri.scheme == 'https' || uri.scheme == 'http') &&
      uri.pathSegments.length == 2 &&
      uri.pathSegments.first == 'invite';
  if (!isSupportedScheme && !isSupportedWebLink) return null;

  final token = isSupportedScheme
      ? (uri.host == 'invite' && uri.pathSegments.length == 1
            ? uri.pathSegments.single
            : null)
      : uri.pathSegments.last;
  if (token == null || !RegExp(r'^[0-9a-fA-F]{48}$').hasMatch(token)) {
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
