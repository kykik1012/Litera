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

  // Ubah Rute dengan Gambar (PUT / POST Method Spoofing)
  Future<Map<String, dynamic>> updateThematicRoute(
    String id, 
    String judul, 
    num panjang, 
    String deskripsi,
    {Uint8List? imageBytes, String? imageFileName} // Tambahan parameter gambar
  ) async {
    final headers = await ApiHelper.authHeaders();
    
    // Hapus header JSON
    headers.remove('Content-Type');
    headers.remove('content-type'); 

    // Gunakan POST, tapi beri tahu server bahwa ini sebenarnya adalah aksi PUT (Update)
    final request = http.MultipartRequest(
      "POST",
      Uri.parse("${Api.baseUrl}/thematic-routes/$id"),
    );

    request.headers.addAll(headers);
    
    // Data form teks
    request.fields['_method'] = 'PUT'; // WAJIB ada agar server menganggap ini PUT
    request.fields['judul_rute'] = judul;
    request.fields['panjang_rute'] = panjang.toString();
    request.fields['deskripsi'] = deskripsi;

    // Masukkan data gambar JIKA user mengganti fotonya
    if (imageBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          "image", // Sesuaikan dengan key di backend ('image', 'gambar', dll)
          imageBytes,
          filename: imageFileName ?? "updated_route_image.jpg",
        ),
      );
    }

    final response = await request.send();
    final body = await response.stream.bytesToString();
    return jsonDecode(body);
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