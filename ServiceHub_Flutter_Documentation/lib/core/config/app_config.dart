class AppConfig {
  const AppConfig._();

  static const apiBaseUrl = String.fromEnvironment(
    'http://192.168.43.76:8080',
    defaultValue: 'http://192.168.43.76:8080',
  );
}
