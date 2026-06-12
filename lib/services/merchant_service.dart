import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api.dart';
import '../helpers/api_helper.dart';

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
}