import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userDataKey = 'user_data'; // 🔥 NEW
  static const String _rememberMeKey = 'remember_me';
  static const String _tokenExpiredAtKey = 'token_expired_at';
  static const String _lastLoginUserIdKey = 'last_login_user_id';

  static late SharedPreferences _prefs;

    /// 🔥 ต้องเรียกก่อนใช้งาน
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }


  static Future<void> saveToken(String token) async {
    await _prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    return _prefs.getString(_tokenKey);
  }

  static Future<void> removeToken() async {
    await _prefs.remove(_tokenKey);
  }

  static Future<void> saveUserId(String userId) async {
    await _prefs.setString(_userIdKey, userId);
  }

  static Future<String?> getUserId() async {
    return _prefs.getString(_userIdKey);
  }

  static Future<void> removeUserId() async {
    await _prefs.remove(_userIdKey);
  }

  static Future<void> saveUserData(String userData) async {
    await _prefs.setString(_userDataKey, userData);
  }

  static Future<String?> getUserData() async {
    return _prefs.getString(_userDataKey);
  }

  static Future<void> removeUserData() async {
    await _prefs.remove(_userDataKey);
  }

  static Future<void> clearAll() async {
    await _prefs.clear();
  }

  static Future<void> saveLastLoginUserId(int userId) async {
    await _prefs.setInt('last_login_user_id', userId);
  }

  static Future<int?> getLastLoginUserId() async {
    return _prefs.getInt('last_login_user_id');
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
