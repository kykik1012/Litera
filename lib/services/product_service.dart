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

  // Mengubah status ketersediaan produk (Tersedia / Habis)
  Future<Map<String, dynamic>> updateProductAvailability(String id, bool isAvailable) async {
    final headers = await ApiHelper.authHeaders();
    headers['Content-Type'] = 'application/json';

    final response = await http.put(
      Uri.parse("${Api.baseUrl}/products/$id/status"),
      headers: headers,
      body: jsonEncode({
        "is_available": isAvailable,
      }),
    );

    return jsonDecode(response.body);
  }

  // Mengupdate detail produk (dengan upload gambar via bytes opsional)
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
    // Pada multipart request boolean biasanya dikirim sebagai string 'true' / 'false' atau '1' / '0'. Kita gunakan '1' / '0'
    request.fields['is_available'] = isAvailable ? "1" : "0";

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

  // Menghapus produk
  Future<Map<String, dynamic>> deleteProduct(String id) async {
    final headers = await ApiHelper.authHeaders();

    final response = await http.delete(
      Uri.parse("${Api.baseUrl}/products/$id"),
      headers: headers,
    );

    return jsonDecode(response.body);
  }
}
