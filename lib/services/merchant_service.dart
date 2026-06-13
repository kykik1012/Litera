import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../constants/api.dart';
import '../helpers/api_helper.dart';
import '../helpers/shared_pref_helper.dart';

class MerchantService {
  // Mengambil semua data merchant
  Future<Map<String, dynamic>> getAllMerchants() async {
    final headers = await ApiHelper.authHeaders();
    
    final response = await http.get(
      Uri.parse("${Api.baseUrl}/merchants"),
      headers: headers,
    );
    
    return jsonDecode(response.body);
  }

  // Mengambil detail merchant berdasarkan ID
  Future<Map<String, dynamic>> getMerchantById(int id) async {
    final headers = await ApiHelper.authHeaders();

    final response = await http.get(
      Uri.parse("${Api.baseUrl}/merchants/$id"),
      headers: headers,
    );

    return jsonDecode(response.body);
  }

  // --- UPDATE STATUS BUKA/TUTUP MERCHANT ---
  Future<Map<String, dynamic>> updateMerchantStatus(String id, String status) async {
    final headers = await ApiHelper.authHeaders();
    final response = await http.put(
      Uri.parse("${Api.baseUrl}/merchants/$id/status"),
      headers: headers,
      body: jsonEncode({
        "status": status, // Mengirim "Buka" atau "Tutup"
      }),
    );

    return jsonDecode(response.body);
  }

  // --- UPDATE INFORMASI MERCHANT ---
  Future<Map<String, dynamic>> updateMerchantInformation({
    required int id,
    required String namaBisnis,
    required String usahaDidirikan,
    required String jamBuka,
    required String jamTutup,
    required String deskripsi,
    Uint8List? imageBytes,
    String? imageFileName,
    Uint8List? qrBytes,
    String? qrFileName,
  }) async {
    final token = await SharedPrefHelper.getToken();
    final request = http.MultipartRequest(
      "PUT",
      Uri.parse("${Api.baseUrl}/merchants/$id/information"),
    );

    request.headers.addAll({
      "Authorization": "Bearer $token",
    });

    request.fields["nama_bisnis"] = namaBisnis;
    request.fields["usaha_didirikan"] = usahaDidirikan;
    request.fields["jam_buka"] = jamBuka;
    request.fields["jam_tutup"] = jamTutup;
    request.fields["deskripsi"] = deskripsi;

    if (imageBytes != null && imageFileName != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          "image_url",
          imageBytes,
          filename: imageFileName,
        ),
      );
    }

    if (qrBytes != null && qrFileName != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          "image_qr",
          qrBytes,
          filename: qrFileName,
        ),
      );
    }

    final response = await request.send();
    final body = await response.stream.bytesToString();
    return jsonDecode(body);
  }
}