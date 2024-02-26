class AuthHelper {
  static String _authToken = '';

  static String get authToken => _authToken;

  static void setAuthToken(String token) {
    _authToken = token;
  }
}