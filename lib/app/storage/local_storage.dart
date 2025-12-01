import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {

  static const _onboardKey = "onboard_done";

  static Future<void> setOnboardDone() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(_onboardKey, true);
  }

  static Future<bool> isOnboardDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardKey) ?? false;
  }


  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }
}
