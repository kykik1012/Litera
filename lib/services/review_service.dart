import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api.dart';
import '../helpers/api_helper.dart';

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

  // 3. POST: Membuat review (Biasanya digunakan oleh Customer, tapi kita siapkan saja)
  Future<Map<String, dynamic>> createReview({
    required int merchantId, 
    required int rating, 
    required String deskripsi,
    // Jika upload gambar menggunakan multipart, kita perlu fungsi terpisah. 
    // Ini asumsi basic JSON POST.
  }) async {
    final headers = await ApiHelper.authHeaders();
    final response = await http.post(
      Uri.parse("${Api.baseUrl}/reviews"),
      headers: headers,
      body: jsonEncode({
        "merchant_id": merchantId,
        "rating": rating,
        "deskripsi": deskripsi,
      }),
    );
    return jsonDecode(response.body);
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