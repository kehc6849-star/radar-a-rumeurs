/// Where the analysis server is, and how to talk to it.
///
/// Values come from the build command (--dart-define), never from the source
/// code: the repository must not contain any address or token of a real server.
class BackendConfiguration {
  const BackendConfiguration({
    required this.baseUrl,
    required this.accessToken,
  });

  /// Without a server address, the application works with local rules only.
  const BackendConfiguration.disabled()
      : baseUrl = '',
        accessToken = '';

  factory BackendConfiguration.fromEnvironment() {
    return const BackendConfiguration(
      baseUrl: String.fromEnvironment('BACKEND_BASE_URL'),
      accessToken: String.fromEnvironment('BACKEND_ACCESS_TOKEN'),
    );
  }

  final String baseUrl;

  /// Optional shared token. It slows down casual abuse but is not a strong secret.
  final String accessToken;

  bool get isConfigured {
    final Uri? parsedAddress = Uri.tryParse(baseUrl.trim());

    if (parsedAddress == null) {
      return false;
    }

    final bool hasWebScheme =
        parsedAddress.scheme == 'http' || parsedAddress.scheme == 'https';

    return hasWebScheme && parsedAddress.host.isNotEmpty;
  }
}
