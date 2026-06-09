import 'dart:convert';

import 'package:http/http.dart'
    as http;

import '../constants/api.dart';

class AuthService {

  // REGISTER
  Future<Map<String, dynamic>>
  register({

    required String username,
    required String name,
    required String email,
    required String password,
    required int role,

  }) async {

    final response =
        await http.post(

      Uri.parse(
        "${Api.baseUrl}/auth/register",
      ),

      headers: {
        "Content-Type":
            "application/json",
      },

      body: jsonEncode({

        "username": username,
        "name": name,
        "email": email,
        "password": password,
        "role": role,

      }),
    );

    return jsonDecode(
      response.body,
    );
  }


  // LOGIN
  Future<Map<String, dynamic>>
  login({

    required String username,
    required String password,

  }) async {

    final response =
        await http.post(

      Uri.parse(
        "${Api.baseUrl}/auth/login",
      ),

      headers: {
        "Content-Type":
            "application/json",
      },

      body: jsonEncode({

        "username": username,
        "password": password,

      }),
    );

    return jsonDecode(
      response.body,
    );
  }
  // SEND RESET OTP
  Future<Map<String, dynamic>>
  sendResetOtp({

    required String email,

  }) async {

    final response =
        await http.post(

      Uri.parse(
        "${Api.baseUrl}/auth/send-reset-otp",
      ),

      headers: {
        "Content-Type":
            "application/json",
      },

      body: jsonEncode({

        "email": email,
      }),
    );

    return jsonDecode(
      response.body,
    );
  }


  // RESET PASSWORD
  Future<Map<String, dynamic>>
  resetPassword({

    required String email,
    required String otp,
    required String newPassword,

  }) async {

    final response =
        await http.post(

      Uri.parse(
        "${Api.baseUrl}/auth/reset-password",
      ),

      headers: {
        "Content-Type":
            "application/json",
      },

      body: jsonEncode({

        "email": email,

        "otp": otp,

        "new_password":
            newPassword,
      }),
    );

    return jsonDecode(
      response.body,
    );
  }
}