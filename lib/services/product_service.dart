import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../constants/api.dart';
import '../helpers/api_helper.dart';
import '../helpers/shared_pref_helper.dart';

class ProductService {
  // Mengambil semua produk
  Future<Map<String, dynamic>> getAllProducts() async {
    final headers = await ApiHelper.authHeaders();

    final response = await http.get(
      Uri.parse("${Api.baseUrl}/products"),
      headers: headers,
    );

    return jsonDecode(response.body);
  }

  // Mengambil produk berdasarkan ID
  Future<Map<String, dynamic>> getProductById(String id) async {
    final headers = await ApiHelper.authHeaders();

    final response = await http.get(
      Uri.parse("${Api.baseUrl}/products/$id"),
      headers: headers,
    );

    return jsonDecode(response.body);
  }

  // Mengambil semua kategori produk dari API
  Future<Map<String, dynamic>> getCategories() async {
    final headers = await ApiHelper.authHeaders();

    final response = await http.get(
      Uri.parse("${Api.baseUrl}/category-products"),
      headers: headers,
    );

    return jsonDecode(response.body);
  }

  // Menambahkan produk baru (dengan upload gambar via bytes)
  Future<Map<String, dynamic>> addProduct({
    required String namaProduk,
    required String deskripsi,
    required int hargaProduk,
    required int categoryId,
    required int merchantId,
    Uint8List? imageBytes,
    String? imageFileName,
  }) async {
    final token = await SharedPrefHelper.getToken();

    final request = http.MultipartRequest(
      "POST",
      Uri.parse("${Api.baseUrl}/products"),
    );

    request.headers.addAll({
      "Authorization": "Bearer $token",
    });

    request.fields['nama_produk'] = namaProduk;
    request.fields['deskripsi'] = deskripsi;
    request.fields['harga_produk'] = hargaProduk.toString();
    request.fields['category_id'] = categoryId.toString();
    request.fields['merchant_id'] = merchantId.toString();

    if (imageBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          "image",
          imageBytes,
          filename: imageFileName ?? "product_image.jpg",
        ),
      );
    }

    final response = await request.send();
    final body = await response.stream.bytesToString();

    return jsonDecode(body);
  }

  // --- DIPERBARUI: Mengubah status ketersediaan produk (Tersedia / Habis) ---
  // Menggunakan PUT /api/products/{id} (Multipart/form-data)
  Future<Map<String, dynamic>> updateProductAvailability({
    required String id,
    required String namaProduk,
    required String deskripsi,
    required int hargaProduk,
    required int categoryId,
    required bool isAvailable,
  }) async {
    final token = await SharedPrefHelper.getToken();

    final request = http.MultipartRequest(
      "PUT",
      Uri.parse("${Api.baseUrl}/products/$id"),
    );

    request.headers.addAll({
      "Authorization": "Bearer $token",
    });

    // Kirim data yang sama persis dengan yang lama, hanya is_available yang berubah
    request.fields['nama_produk'] = namaProduk;
    request.fields['deskripsi'] = deskripsi;
    request.fields['harga_produk'] = hargaProduk.toString();
    request.fields['category_id'] = categoryId.toString();
    
    // API Multipart biasanya meminta string boolean ("true"/"false") 
    request.fields['is_available'] = isAvailable.toString(); 
    
    // Karena kita hanya ubah status HABIS/TERSEDIA, kita tidak mengirim file 'image'
    
    final response = await request.send();
    final body = await response.stream.bytesToString();

    return jsonDecode(body);
  }

  // Mengupdate detail produk BESERTA Gambar
  Future<Map<String, dynamic>> updateProduct({
    required String id,
    required String namaProduk,
    required String deskripsi,
    required int hargaProduk,
    required int categoryId,
    required bool isAvailable,
    Uint8List? imageBytes,
    String? imageFileName,
  }) async {
    final token = await SharedPrefHelper.getToken();

    final request = http.MultipartRequest(
      "PUT",
      Uri.parse("${Api.baseUrl}/products/$id"),
    );

    request.headers.addAll({
      "Authorization": "Bearer $token",
    });

    request.fields['nama_produk'] = namaProduk;
    request.fields['deskripsi'] = deskripsi;
    request.fields['harga_produk'] = hargaProduk.toString();
    request.fields['category_id'] = categoryId.toString();
    request.fields['is_available'] = isAvailable.toString();

    if (imageBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          "image",
          imageBytes,
          filename: imageFileName ?? "product_image_updated.jpg",
        ),
      );
    }

    final response = await request.send();
    final body = await response.stream.bytesToString();

    return jsonDecode(body);
  }

  // --- DIPERBARUI: Menghapus produk (Soft Delete) ---
  // Menggunakan PUT /api/products/{id}/status dengan format application/json
  Future<Map<String, dynamic>> deleteProduct(String id) async {
    final headers = await ApiHelper.authHeaders();
    headers['Content-Type'] = 'application/json';

    final response = await http.put(
      Uri.parse("${Api.baseUrl}/products/$id/status"),
      headers: headers,
      body: jsonEncode({
        "is_active": false, // Mengirim data sesuai endpoint Gambar 2
      }),
    );

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> restoreProduct(String id) async {
    final headers = await ApiHelper.authHeaders();
    headers['Content-Type'] = 'application/json';

    final response = await http.put(
      Uri.parse("${Api.baseUrl}/products/$id/status"),
      headers: headers,
      body: jsonEncode({
        "is_active": true, // Mengembalikan status aktif menjadi true
      }),
    );

    return jsonDecode(response.body);
  }
}