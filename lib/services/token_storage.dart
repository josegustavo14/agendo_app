import 'package:shared_preferences/shared_preferences.dart';

/// Persists JWT tokens per account using SharedPreferences.
/// Works on all platforms including web (localStorage).
/// Key scheme: `token_<email>` + `last_email` to know which was active last.
class TokenStorage {
  static const _lastEmailKey = 'last_email';

  static String _tokenKey(String email) => 'token_$email';

  Future<void> saveToken(String email, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey(email), token);
    await prefs.setString(_lastEmailKey, email);
  }

  /// Returns the token for the last logged-in account, or null if none.
  Future<({String email, String token})?> getLastSession() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_lastEmailKey);
    if (email == null) return null;
    final token = prefs.getString(_tokenKey(email));
    if (token == null) return null;
    return (email: email, token: token);
  }

  Future<void> clearToken(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey(email));
    final lastEmail = prefs.getString(_lastEmailKey);
    if (lastEmail == email) {
      await prefs.remove(_lastEmailKey);
    }
  }
}
