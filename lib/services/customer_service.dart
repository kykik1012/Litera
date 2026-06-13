import 'dart:convert';

import 'package:http/http.dart'
    as http;

import '../constants/api.dart';
import '../helpers/api_helper.dart';

class CustomerService {

  Future<List<dynamic>> getCustomers() async {

    final headers =
        await ApiHelper.authHeaders();

    final response =
        await http.get(

      Uri.parse(
        "${Api.baseUrl}/customers",
      ),

      headers: headers,
    );

    final data =
        jsonDecode(
      response.body,
    );

    print("CUSTOMER RESPONSE");
    print(data);

    if (data["data"] == null) {

      return [];
    }

    return List<dynamic>.from(
      data["data"],
    );
  }
}
