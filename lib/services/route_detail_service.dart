import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api.dart';
import '../helpers/api_helper.dart';

class RouteDetailService {
  
  // Ambil detail rute
  Future<Map<String, dynamic>> getAllRouteDetails() async {
    // 1. Ambil header yang berisi token
    final headers = await ApiHelper.authHeaders();
    
    final response = await http.get(
      Uri.parse("${Api.baseUrl}/route-details"),
      headers: headers, // 2. Sisipkan header di sini
    );
    
    print("Status Code Detail: ${response.statusCode}");
    print("Body Detail: ${response.body}");
    
    return jsonDecode(response.body);
  }

}