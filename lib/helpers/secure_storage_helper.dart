import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageHelper {

  static const storage =
      FlutterSecureStorage();

  // =========================
  // BIOMETRIC STATUS
  // =========================

  static Future<void>
      saveBiometricEnabled({

    required bool enabled,

    required int userId,

    required int role,
  }) async {

    await storage.write(
      key: "biometric_enabled",
      value: enabled.toString(),
    );

    await storage.write(
      key: "biometric_user_id",
      value: userId.toString(),
    );

    await storage.write(
      key: "biometric_role",
      value: role.toString(),
    );
  }

  static Future<bool>
      isBiometricEnabled()
  async {

    final value =
        await storage.read(
      key: "biometric_enabled",
    );

    return value == "true";
  }

  static Future<bool>
      isBiometricForUser(
    int userId,
  ) async {

    final enabled =
        await storage.read(
      key: "biometric_enabled",
    );

    final savedUserId =
        await storage.read(
      key: "biometric_user_id",
    );

    return enabled == "true" &&
        savedUserId ==
            userId.toString();
  }

  // =========================
  // BIOMETRIC USER DATA
  // =========================

  static Future<void>
      saveBiometricUserData({

    required String token,

    required int userId,

    required String username,

    required String email,

    required int role,
  }) async {

    await storage.write(
      key: "biometric_token",
      value: token,
    );

    await storage.write(
      key: "biometric_user_id",
      value: userId.toString(),
    );

    await storage.write(
      key: "biometric_username",
      value: username,
    );

    await storage.write(
      key: "biometric_email",
      value: email,
    );

    await storage.write(
      key: "biometric_role",
      value: role.toString(),
    );
  }

  static Future<String?>
      getBiometricToken()
  async {

    return await storage.read(
      key: "biometric_token",
    );
  }

  static Future<String?>
      getBiometricUserId()
  async {

    return await storage.read(
      key: "biometric_user_id",
    );
  }

  static Future<String?>
      getBiometricUsername()
  async {

    return await storage.read(
      key: "biometric_username",
    );
  }

  static Future<String?>
      getBiometricEmail()
  async {

    return await storage.read(
      key: "biometric_email",
    );
  }

  static Future<String?>
      getBiometricRole()
  async {

    return await storage.read(
      key: "biometric_role",
    );
  }

  // =========================
  // REMOVE BIOMETRIC
  // =========================

  static Future<void>
      removeBiometric()
  async {

    await storage.delete(
      key: "biometric_enabled",
    );

    await storage.delete(
      key: "biometric_user_id",
    );

    await storage.delete(
      key: "biometric_role",
    );

    await storage.delete(
      key: "biometric_token",
    );

    await storage.delete(
      key: "biometric_username",
    );

    await storage.delete(
      key: "biometric_email",
    );
  }
}
