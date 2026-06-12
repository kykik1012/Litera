import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api.dart';
import '../helpers/api_helper.dart';
import 'dart:io';

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

  // --- UPDATE INFORMASI MERCHANT (MULTIPART) ---
  Future<Map<String, dynamic>> updateMerchantInformation({
    required String id,
    required String namaBisnis,
    required String usahaDidirikan, // Format: YYYY-MM-DD
    required String jamBuka,        // Format: HH:mm
    required String jamTutup,       // Format: HH:mm
    required String deskripsi,
    File? imageProfile,             // Untuk parameter image_url
    File? imageQr,                  // Untuk parameter image_qr
  }) async {
    final headers = await ApiHelper.authHeaders();
    
    // Hapus header JSON karena kita pakai Multipart
    headers.remove('Content-Type');
    headers.remove('content-type');

    // Trik standar: Gunakan POST lalu tambahkan _method = PUT agar server (terutama Laravel) bisa membaca file multipart dengan benar
    final request = http.MultipartRequest(
      "POST", 
      Uri.parse("${Api.baseUrl}/merchants/$id/information"),
    );

    request.headers.addAll(headers);
    request.fields['_method'] = 'PUT'; // Wajib ada untuk mode PUT Multipart
    request.fields['nama_bisnis'] = namaBisnis;
    request.fields['usaha_didirikan'] = usahaDidirikan;
    request.fields['jam_buka'] = jamBuka;
    request.fields['jam_tutup'] = jamTutup;
    request.fields['deskripsi'] = deskripsi;

    // Masukkan file jika user memilih gambar baru
    if (imageProfile != null) {
      request.files.add(await http.MultipartFile.fromPath('image_url', imageProfile.path));
    }
    if (imageQr != null) {
      request.files.add(await http.MultipartFile.fromPath('image_qr', imageQr.path));
    }

    final response = await request.send();
    final body = await response.stream.bytesToString();
    return jsonDecode(body);
  }
}