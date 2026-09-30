/// Optional compile-time Web OAuth client ID.
///
/// Android Google Sign-In needs the Web application OAuth client ID when
/// google-services.json is not used. It can be supplied with:
///
/// flutter run --dart-define=TASKLY_GOOGLE_SERVER_CLIENT_ID=xxx.apps.googleusercontent.com
const googleServerClientId = String.fromEnvironment(
  'TASKLY_GOOGLE_SERVER_CLIENT_ID',
  defaultValue: '',
);

bool isValidGoogleWebClientId(String value) {
  final id = value.trim();
  return RegExp(r'^\\d+-[A-Za-z0-9_-]+\\.apps\\.googleusercontent\\.com$').hasMatch(id);
}
