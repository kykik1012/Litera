import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../constants/api.dart';
import '../helpers/api_helper.dart';
import '../helpers/shared_pref_helper.dart';

class UserService {

  // GET USER BY ID
  Future<Map<String, dynamic>> getUserById(
    int id,
  ) async {

    final response =
        await http.get(

      Uri.parse(
        "${Api.baseUrl}/users/$id",
      ),

      headers:
          await ApiHelper
              .authHeaders(),
    );

    return jsonDecode(
      response.body,
    );
  }

  // UPDATE CUSTOMER
  Future<Map<String, dynamic>>
  updateCustomer({

    required int id,
    required String name,

  }) async {

    final response =
        await http.put(

      Uri.parse(
        "${Api.baseUrl}/users/$id",
      ),

      headers:
          await ApiHelper
              .authHeaders(),

      body: jsonEncode({

        "name": name,
      }),
    );

    return jsonDecode(
      response.body,
    );
  }

  // UPDATE MERCHANT
  Future<Map<String, dynamic>> updateMerchant({
    required int id,
    required String namaBisnis,
    required String deskripsi,
    required String usahaDidirikan, // Diubah dari int tahunBerdiri ke String format tanggal (YYYY-MM-DD)
    required String jamBuka,        // Tambahan parameter baru
    required String jamTutup,       // Tambahan parameter baru
  }) async {
    final response = await http.put(
      Uri.parse("${Api.baseUrl}/users/$id"),
      headers: await ApiHelper.authHeaders(),
      body: jsonEncode({
        "nama_bisnis": namaBisnis,
        "deskripsi": deskripsi,
        // Sesuaikan dengan key JSON yang diminta backend temanmu:
        "usaha_didirikan": usahaDidirikan, 
        "jam_buka": jamBuka,
        "jam_tutup": jamTutup,
      }),
    );

    return jsonDecode(response.body);
  }

  // UPLOAD PROFILE PICTURE
  Future<Map<String, dynamic>>
  uploadProfilePicture({

    required int id,
    required File image,

  }) async {

    final token =
        await SharedPrefHelper
            .getToken();

    final request =
        http.MultipartRequest(

      "PUT",

      Uri.parse(
        "${Api.baseUrl}/users/upload-profile/$id",
      ),
    );

    request.headers.addAll({

      "Authorization":
          "Bearer $token",
    });

    request.files.add(

      await http.MultipartFile
          .fromPath(

        "profile_picture",

        image.path,
      ),
    );

    final response =
        await request.send();

    final body =
        await response.stream
            .bytesToString();

    return jsonDecode(
      body,
    );
  }

  // --- TAMBAHAN UNTUK FITUR KELOLA AKUN ---

  // 1. MENGAMBIL SEMUA DATA USER
  Future<Map<String, dynamic>> getAllUsers() async {
    final response = await http.get(
      Uri.parse("${Api.baseUrl}/users"),
      headers: await ApiHelper.authHeaders(),
    );

    return jsonDecode(response.body);
  }

  // 2. SOFT DELETE USER
  Future<Map<String, dynamic>> deleteUser(String id) async {
    final response = await http.delete(
      Uri.parse("${Api.baseUrl}/users/$id"),
      headers: await ApiHelper.authHeaders(),
    );

    return jsonDecode(response.body);
  }

  // 3. RESTORE USER (MENGAKTIFKAN KEMBALI)
  Future<Map<String, dynamic>> restoreUser(String id) async {
    final response = await http.put(
      Uri.parse("${Api.baseUrl}/users/restore/$id"),
      headers: await ApiHelper.authHeaders(),
    );

    return jsonDecode(response.body);
  }
}