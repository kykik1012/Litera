import 'package:local_auth/local_auth.dart';

class BiometricService {

  final LocalAuthentication auth =
      LocalAuthentication();

  Future<bool> isAvailable() async {

    try {

      final canCheck =
          await auth.canCheckBiometrics;

      final isSupported =
          await auth.isDeviceSupported();

      print(
        "CAN CHECK = $canCheck",
      );

      print(
        "SUPPORTED = $isSupported",
      );

      return canCheck ||
          isSupported;

    } catch (e) {

      print(
        "AVAILABLE ERROR = $e",
      );

      return false;
    }
  }

  Future<bool> authenticate() async {

    try {

      print(
        "AUTH START",
      );

      final result =
          await auth.authenticate(
        localizedReason:
            "Verifikasi sidik jari untuk masuk",
      );

      print(
        "AUTH RESULT = $result",
      );

      return result;

    } catch (e) {

      print(
        "AUTH ERROR = $e",
      );

      return false;
    }
  }
}
