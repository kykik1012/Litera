import 'dart:convert';
import 'dart:typed_data'; // Tambahkan ini untuk Uint8List (Byte Gambar)
import 'package:http/http.dart' as http;
import '../constants/api.dart';
import '../helpers/api_helper.dart';
import '../helpers/shared_pref_helper.dart';

class ReviewService {
  
  // 1. GET: Mengambil semua review
  Future<Map<String, dynamic>> getAllReviews() async {
    final headers = await ApiHelper.authHeaders();
    final response = await http.get(
      Uri.parse("${Api.baseUrl}/reviews"),
      headers: headers,
    );
    return jsonDecode(response.body);
  }

  // 2. GET: Mengambil detail review berdasarkan ID
  Future<Map<String, dynamic>> getReviewById(String id) async {
    final headers = await ApiHelper.authHeaders();
    final response = await http.get(
      Uri.parse("${Api.baseUrl}/reviews/$id"),
      headers: headers,
    );
    return jsonDecode(response.body);
  }

  // 3. POST: Membuat review (MENCARI CUSTOMER ID SECARA OTOMATIS)
  Future<Map<String, dynamic>> createReview({
    required int merchantId, 
    required int rating, 
    required String deskripsi,
    Uint8List? imageBytes,   
    String? imageFileName,   
  }) async {
    final headers = await ApiHelper.authHeaders();
    
    // Hapus header JSON agar MultipartRequest bisa bekerja
    headers.remove('Content-Type');
    headers.remove('content-type'); 

    // --- 1. AMBIL USER_ID DARI SHARED PREFERENCES ---
    final int? userId = await SharedPrefHelper.getUserId();
    String finalCustomerId = "";

    if (userId != null) {
      try {
        // --- 2. PANGGIL API CUSTOMERS UNTUK MENCARI CUSTOMER_ID ---
        final customerRes = await http.get(
          Uri.parse("${Api.baseUrl}/customers"),
          headers: await ApiHelper.authHeaders(), // Pakai header auth yang utuh
        );
        
        final customerData = jsonDecode(customerRes.body);

        if (customerData['success'] == true) {
          final List<dynamic> customersList = customerData['data'];
          
          // Cari customer yang 'user_id'-nya sama dengan userId kita di SharedPref
          final myCustomerProfile = customersList.firstWhere(
            (c) => c['user_id'].toString() == userId.toString(),
            orElse: () => null,
          );

          if (myCustomerProfile != null) {
            finalCustomerId = myCustomerProfile['id'].toString(); // Inilah Customer ID aslinya!
          }
        }
      } catch (e) {
        throw Exception("Gagal terhubung ke data Customer: $e");
      }
    }

    // Cegah proses jika Customer ID tidak ketemu
    if (finalCustomerId.isEmpty) {
      throw Exception("Profil Customer tidak ditemukan untuk akun ini. Pastikan profilmu sudah terdaftar.");
    }

    // --- 3. LANJUTKAN PROSES UPLOAD ULASAN SEPERTI BIASA ---
    final request = http.MultipartRequest(
      "POST",
      Uri.parse("${Api.baseUrl}/reviews"),
    );

    request.headers.addAll(headers);

    // Masukkan data dengan customer_id yang sudah tepat
    request.fields['customer_id'] = finalCustomerId; 
    request.fields['merchant_id'] = merchantId.toString();
    request.fields['rating'] = rating.toString();
    request.fields['deskripsi'] = deskripsi;

    if (imageBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          "image", 
          imageBytes,
          filename: imageFileName ?? "review_image.jpg",
        ),
      );
    }

    final response = await request.send();
    final body = await response.stream.bytesToString();

    return jsonDecode(body);
  }
  // 4. DELETE: Soft delete review
  Future<Map<String, dynamic>> deleteReview(String id) async {
    final headers = await ApiHelper.authHeaders();
    final response = await http.delete(
      Uri.parse("${Api.baseUrl}/reviews/$id"),
      headers: headers,
    );
    return jsonDecode(response.body);
  }

  // 5. PUT: Memulihkan review (Restore)
  Future<Map<String, dynamic>> restoreReview(String id) async {
    final headers = await ApiHelper.authHeaders();
    final response = await http.put(
      Uri.parse("${Api.baseUrl}/reviews/restore/$id"),
      headers: headers,
    );
    return jsonDecode(response.body);
  }
}