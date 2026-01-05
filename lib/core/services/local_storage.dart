import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userDataKey = 'user_data'; // 🔥 NEW
  static const String _rememberMeKey = 'remember_me';
  static const String _tokenExpiredAtKey = 'token_expired_at';
  static const String _lastLoginUserIdKey = 'last_login_user_id';


  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  static Future<void> removeUserId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
  }

  static Future<void> saveUserData(String userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userDataKey, userData);
  }

  static Future<String?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userDataKey);
  }

  static Future<void> removeUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userDataKey);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<void> saveLastLoginUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_login_user_id', userId);
  }

  static Future<int?> getLastLoginUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('last_login_user_id');
  }

  /* ================= 🔥 REMEMBER ME ================= */

  static Future<void> saveRememberMe(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, value);
  }

  static Future<bool> getRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberMeKey) ?? false;
  }

  static Future<void> removeRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_rememberMeKey);
  }

  /* ================= 🔥 TOKEN EXPIRE (OPTIONAL) ================= */

  static Future<void> saveTokenExpiredAt(DateTime dateTime) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _tokenExpiredAtKey,
      dateTime.toIso8601String(),
    );
  }

  static Future<DateTime?> getTokenExpiredAt() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_tokenExpiredAtKey);
    return value != null ? DateTime.parse(value) : null;
  }

  static Future<void> removeTokenExpiredAt() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenExpiredAtKey);
  }


  /// 🔥 ใช้กับ forgot password / logout
  static Future<void> clearAuthSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_lastLoginUserIdKey);
    await prefs.remove(_rememberMeKey);
    await prefs.remove(_tokenExpiredAtKey);
  }
  
}
