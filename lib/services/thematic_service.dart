import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api.dart';
import 'dart:typed_data';
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

  Future<Map<String, dynamic>> createThematicRoute(
    String judul, 
    num panjang, 
    String deskripsi, 
    {Uint8List? imageBytes, String? imageFileName} // Parameter opsional untuk gambar
  ) async {
    final headers = await ApiHelper.authHeaders();
    
    // Hapus header JSON agar MultipartRequest bisa bekerja dengan benar
    headers.remove('Content-Type');
    headers.remove('content-type'); 

    final request = http.MultipartRequest(
      "POST",
      Uri.parse("${Api.baseUrl}/thematic-routes"),
    );

    request.headers.addAll(headers);

    // Masukkan data teks
    request.fields['judul_rute'] = judul;
    request.fields['panjang_rute'] = panjang.toString();
    request.fields['deskripsi'] = deskripsi;

    // Masukkan data gambar jika user mengunggahnya
    if (imageBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          "image", // PASTIKAN key ini sesuai dengan yang diminta oleh backend temanmu (bisa jadi 'image', 'gambar', atau 'image_url')
          imageBytes,
          filename: imageFileName ?? "thematic_route_image.jpg",
        ),
      );
    }

    final response = await request.send();
    final body = await response.stream.bytesToString();
    return jsonDecode(body);
  }

  // Ubah Rute dengan Gambar (PUT Multipart, dengan fallback POST+_method)
  Future<Map<String, dynamic>> updateThematicRoute(
    String id, 
    String judul, 
    num panjang, 
    String deskripsi,
    {Uint8List? imageBytes, String? imageFileName}
  ) async {
    // Coba PUT langsung terlebih dahulu
    var result = await _sendUpdateRequest(
      id, judul, panjang, deskripsi,
      method: "PUT",
      imageBytes: imageBytes,
      imageFileName: imageFileName,
    );

    // Jika server mengembalikan HTML (PUT multipart tidak didukung), 
    // fallback ke POST + _method=PUT (Laravel method spoofing)
    if (result['_isHtml'] == true) {
      print("PUT multipart gagal, mencoba POST + _method=PUT...");
      result = await _sendUpdateRequest(
        id, judul, panjang, deskripsi,
        method: "POST",
        useMethodSpoofing: true,
        imageBytes: imageBytes,
        imageFileName: imageFileName,
      );
    }

    // Bersihkan flag internal sebelum return
    result.remove('_isHtml');
    return result;
  }

  /// Helper internal untuk mengirim request update
  Future<Map<String, dynamic>> _sendUpdateRequest(
    String id,
    String judul,
    num panjang,
    String deskripsi, {
    required String method,
    bool useMethodSpoofing = false,
    Uint8List? imageBytes,
    String? imageFileName,
  }) async {
    final headers = await ApiHelper.authHeaders();
    headers.remove('Content-Type');
    headers.remove('content-type');

    final request = http.MultipartRequest(
      method,
      Uri.parse("${Api.baseUrl}/thematic-routes/$id"),
    );

    request.headers.addAll(headers);

    // Jika menggunakan method spoofing (Laravel)
    if (useMethodSpoofing) {
      request.fields['_method'] = 'PUT';
    }

    request.fields['judul_rute'] = judul;
    request.fields['panjang_rute'] = panjang.toString();
    request.fields['deskripsi'] = deskripsi;

    if (imageBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          "image",
          imageBytes,
          filename: imageFileName ?? "updated_route_image.jpg",
        ),
      );
    }

    final response = await request.send();
    final body = await response.stream.bytesToString();

    print("[$method] Update Route Status: ${response.statusCode}");
    print("[$method] Update Route Body: ${body.length > 200 ? body.substring(0, 200) : body}");

    // Cek apakah response adalah HTML (bukan JSON)
    if (body.trimLeft().startsWith('<')) {
      return {
        '_isHtml': true,
        'success': false,
        'message': 'Server mengembalikan respons tidak valid (status: ${response.statusCode})',
      };
    }

    try {
      return jsonDecode(body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal memproses respons server: $e',
      };
    }
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