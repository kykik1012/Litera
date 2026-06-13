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

  // --- UPDATE LOKASI MERCHANT ---
  Future<Map<String, dynamic>> updateMerchantLocation({
    required int id,
    required double latitude,
    required double longitude,
  }) async {
    final headers = await ApiHelper.authHeaders();
    headers['Content-Type'] = 'application/json';

    String alamat = "-";
    bool isActive = true;
    
    // Coba ambil data lokasi yang sudah ada untuk mempertahankan alamat & is_active
    try {
      final getResponse = await http.get(
        Uri.parse("${Api.baseUrl}/merchant-locations/$id"),
        headers: headers,
      );
      if (getResponse.statusCode == 200) {
        final data = jsonDecode(getResponse.body);
        if (data['success'] == true && data['data'] != null) {
          alamat = data['data']['alamat'] ?? "-";
          isActive = data['data']['is_active'] ?? true;
        }
      }
    } catch (e) {
      // Abaikan error saat GET
    }

    // Lakukan PUT untuk update lokasi (menggunakan endpoint yang benar)
    var response = await http.put(
      Uri.parse("${Api.baseUrl}/merchant-locations/$id"),
      headers: headers,
      body: jsonEncode({
        "latitude": latitude,
        "longitude": longitude,
        "alamat": alamat,
        "is_active": isActive,
      }),
    );

    var responseData = jsonDecode(response.body);

    // Jika lokasi tidak ditemukan (baru pertama kali set), lakukan POST untuk create
    if (response.statusCode == 404 || 
       (responseData['success'] == false && responseData['message']?.toString().toLowerCase().contains('tidak ditemukan') == true)) {
      response = await http.post(
        Uri.parse("${Api.baseUrl}/merchant-locations"),
        headers: headers,
        body: jsonEncode({
          "merchant_id": id,
          "latitude": latitude,
          "longitude": longitude,
          "alamat": alamat,
        }),
      );
      responseData = jsonDecode(response.body);
    }

    return responseData;
  }
}