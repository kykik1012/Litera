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

  // --- DIPERBARUI: UPDATE INFORMASI BISNIS MERCHANT ---
  // (Menggunakan Endpoint dari Gambar Swagger)
  Future<Map<String, dynamic>> updateMerchantInformation({
    required int id,
    String? namaBisnis,
    String? usahaDidirikan,
    String? jamBuka,
    String? jamTutup,
    String? deskripsi,
    double? latitude,
    double? longitude,
    String? alamat,
    Uint8List? imageBytes,
    String? imageFileName,
  }) async {
    final token = await SharedPrefHelper.getToken();
    final request = http.MultipartRequest(
      "PUT",
      Uri.parse("${Api.baseUrl}/merchants/$id/information"),
    );

    request.headers.addAll({
      "Authorization": "Bearer $token",
    });

    // Menambahkan field teks hanya jika tidak null/kosong
    if (namaBisnis != null) request.fields["nama_bisnis"] = namaBisnis;
    if (usahaDidirikan != null) request.fields["usaha_didirikan"] = usahaDidirikan;
    if (jamBuka != null) request.fields["jam_buka"] = jamBuka;
    if (jamTutup != null) request.fields["jam_tutup"] = jamTutup;
    if (deskripsi != null) request.fields["deskripsi"] = deskripsi;
    if (alamat != null) request.fields["alamat"] = alamat;
    if (latitude != null) request.fields["latitude"] = latitude.toString();
    if (longitude != null) request.fields["longitude"] = longitude.toString();

    // Menambahkan Foto Utama Merchant
    if (imageBytes != null && imageFileName != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          "image_url", // Sesuai dengan field di Swagger
          imageBytes,
          filename: imageFileName,
        ),
      );
    }

    final response = await request.send();
    final body = await response.stream.bytesToString();
    return jsonDecode(body);
  }

  // --- DIPERBARUI: UPDATE LOKASI MERCHANT ---
  // Karena temanmu menggabungkannya di endpoint '/information',
  // fungsi ini sekarang cukup memanggil updateMerchantInformation 
  // dengan hanya mengirimkan koordinat latitude dan longitude.
  Future<Map<String, dynamic>> updateMerchantLocation({
    required int id,
    required double latitude,
    required double longitude,
  }) async {
    
    // Ambil data alamat lama terlebih dahulu agar tidak hilang (opsional, sebagai jaga-jaga)
    String? oldAlamat;
    try {
      final oldData = await getMerchantById(id);
      if (oldData['success'] == true && oldData['data'] != null) {
        oldAlamat = oldData['data']['alamat'];
      }
    } catch (_) {}

    // Lakukan update lokasi ke endpoint utama /information
    return await updateMerchantInformation(
      id: id,
      latitude: latitude,
      longitude: longitude,
      alamat: oldAlamat ?? "-", // Set default "-" jika kosong
    );
  }
}