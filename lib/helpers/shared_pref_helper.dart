import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefHelper {

  static Future<void> saveUserData({

    required String token,
    required int id,
    required String username,
    required String email,
    required int role,

  }) async {

    final prefs =
        await SharedPreferences
            .getInstance();

    await prefs.setString(
      "token",
      token,
    );

    await prefs.setInt(
      "user_id",
      id,
    );

    await prefs.setString(
      "username",
      username,
    );

    await prefs.setString(
      "email",
      email,
    );

    await prefs.setInt(
      "role",
      role,
    );
  }

  static Future<String?> getToken() async {

    final prefs =
        await SharedPreferences
            .getInstance();

    return prefs.getString(
      "token",
    );
  }

  static Future<int?> getUserId() async {

    final prefs =
        await SharedPreferences
            .getInstance();

    return prefs.getInt(
      "user_id",
    );
  }

  static Future<String?> getUsername() async {

    final prefs =
        await SharedPreferences
            .getInstance();

    return prefs.getString(
      "username",
    );
  }

  static Future<String?> getEmail() async {

    final prefs =
        await SharedPreferences
            .getInstance();

    return prefs.getString(
      "email",
    );
  }

  static Future<int?> getRole() async {

    final prefs =
        await SharedPreferences
            .getInstance();

    return prefs.getInt(
      "role",
    );
  }

  static Future<void> logout() async {

    final prefs =
        await SharedPreferences
            .getInstance();

    await prefs.clear();
  }
}