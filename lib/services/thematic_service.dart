import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api.dart';
import '../helpers/api_helper.dart'; // Pastikan import ApiHelper

class ThematicRouteService {
  
  // Ambil semua thematic routes
  Future<Map<String, dynamic>> getAllThematicRoutes() async {
    // 1. Ambil header yang berisi token
    final headers = await ApiHelper.authHeaders();
    
    final response = await http.get(
      Uri.parse("${Api.baseUrl}/thematic-routes"),
      headers: headers, // 2. Sisipkan header di sini
    );
    
    print("Status Code Rute: ${response.statusCode}");
    print("Body Rute: ${response.body}");
    
    return jsonDecode(response.body);
  }
// --- TAMBAHAN FITUR KELOLA RUTE ---

  // Tambah Rute Baru (POST)
  Future<Map<String, dynamic>> createThematicRoute(String judul, num panjang, String deskripsi) async {
    final headers = await ApiHelper.authHeaders();
    final response = await http.post(
      Uri.parse("${Api.baseUrl}/thematic-routes"),
      headers: headers,
      body: jsonEncode({
        "judul_rute": judul,
        "panjang_rute": panjang,
        "deskripsi": deskripsi,
      }),
    );
    return jsonDecode(response.body);
  }

  // Ubah Rute (PUT)
  Future<Map<String, dynamic>> updateThematicRoute(String id, String judul, num panjang, String deskripsi) async {
    final headers = await ApiHelper.authHeaders();
    final response = await http.put(
      Uri.parse("${Api.baseUrl}/thematic-routes/$id"),
      headers: headers,
      body: jsonEncode({
        "judul_rute": judul,
        "panjang_rute": panjang,
        "deskripsi": deskripsi,
      }),
    );
    return jsonDecode(response.body);
  }

  // Soft Delete Rute (DELETE)
  Future<Map<String, dynamic>> deleteThematicRoute(String id) async {
    final headers = await ApiHelper.authHeaders();
    final response = await http.delete(
      Uri.parse("${Api.baseUrl}/thematic-routes/$id"),
      headers: headers,
    );
    return jsonDecode(response.body);
  }

  // Restore Rute (PUT)
  Future<Map<String, dynamic>> restoreThematicRoute(String id) async {
    final headers = await ApiHelper.authHeaders();
    final response = await http.put(
      Uri.parse("${Api.baseUrl}/thematic-routes/restore/$id"),
      headers: headers,
    );
    return jsonDecode(response.body);
  }
}