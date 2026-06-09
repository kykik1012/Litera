import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api.dart';
import '../helpers/api_helper.dart';

class RouteDetailService {
  
  // 1. GET: Mengambil semua route detail
  Future<Map<String, dynamic>> getAllRouteDetails() async {
    final headers = await ApiHelper.authHeaders();
    
    final response = await http.get(
      Uri.parse("${Api.baseUrl}/route-details"),
      headers: headers,
    );
    
    return jsonDecode(response.body);
  }

  // 2. GET: Mengambil detail route berdasarkan ID
  Future<Map<String, dynamic>> getRouteDetailById(String id) async {
    final headers = await ApiHelper.authHeaders();
    
    final response = await http.get(
      Uri.parse("${Api.baseUrl}/route-details/$id"),
      headers: headers,
    );
    
    return jsonDecode(response.body);
  }

  // 3. POST: Menambahkan route detail baru
  // Biasanya, untuk menyambungkan rute dengan merchant, kamu hanya perlu mengirim ID-nya saja
  Future<Map<String, dynamic>> createRouteDetail({
    required int merchantId, 
    required int thematicRouteId
  }) async {
    final headers = await ApiHelper.authHeaders();
    
    final response = await http.post(
      Uri.parse("${Api.baseUrl}/route-details"),
      headers: headers,
      body: jsonEncode({
        "merchant_id": merchantId,
        "thematic_route_id": thematicRouteId,
      }),
    );
    
    return jsonDecode(response.body);
  }

  // 4. DELETE: Menghapus route detail
  Future<Map<String, dynamic>> deleteRouteDetail(String id) async {
    final headers = await ApiHelper.authHeaders();
    
    final response = await http.delete(
      Uri.parse("${Api.baseUrl}/route-details/$id"),
      headers: headers,
    );
    
    return jsonDecode(response.body);
  }
}