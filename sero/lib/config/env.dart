class Environment {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api/v1',
  );

  static const String fallbackUrl = String.fromEnvironment(
    'FALLBACK_URL',
    defaultValue: 'http://192.168.1.1:3000/api/v1',
  );
}
