import 'package:litera/helpers/shared_pref_helper.dart';

class ApiHelper {

  static Future<Map<String, String>>
  authHeaders() async {

    final token =
        await SharedPrefHelper
            .getToken();

    return {

      "Content-Type":
          "application/json",

      "Authorization":
          "Bearer $token",
    };
  }
}