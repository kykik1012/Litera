import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api.dart';
import '../helpers/shared_pref_helper.dart';

class PromotionService {
  Future<Map<String, dynamic>> getAllPromotions() async {
    try {
      final token = await SharedPrefHelper.getToken();

      final response = await http.get(
        Uri.parse('${Api.baseUrl}/promotions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> createPromotion({
    required int productId,
    required String tipePromo,
    required int diskon,
    required int kuota,
    required String tanggalBerlaku,
    required String tanggalExpired,
  }) async {
    try {
      final token = await SharedPrefHelper.getToken();

      final response = await http.post(
        Uri.parse('${Api.baseUrl}/promotions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'product_id': productId,
          'tipe_promo': tipePromo,
          'diskon': diskon,
          'kuota': kuota,
          'tanggal_berlaku': tanggalBerlaku,
          'tanggal_expired': tanggalExpired,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> claimPromotion({
    required int customerId,
    required int promotionId,
  }) async {
    try {
      final token = await SharedPrefHelper.getToken();

      final response = await http.post(
        Uri.parse('${Api.baseUrl}/customer-vouchers'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'customer_id': customerId,
          'promotion_id': promotionId,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // --- MENGAMBIL SEMUA VOUCHER CUSTOMER ---
  Future<Map<String, dynamic>> getCustomerVouchers() async {
    try {
      final token = await SharedPrefHelper.getToken();

      final response = await http.get(
        Uri.parse('${Api.baseUrl}/customer-vouchers'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // --- FUNGSI MENGEDIT PROMO ---
  Future<Map<String, dynamic>> updatePromotion({
    required String promotionId,
    required int productId,
    required String tipePromo,
    required int diskon,
    required int kuota,
    required String tanggalBerlaku,
    required String tanggalExpired,
  }) async {
    try {
      final token = await SharedPrefHelper.getToken();

      // Sesuaikan URL ini dengan endpoint update di backend-mu
      // Contoh standar REST API: PUT /api/promotions/{id}
      final response = await http.put(
        Uri.parse('${Api.baseUrl}/promotions/$promotionId'), 
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'product_id': productId,
          'tipe_promo': tipePromo,
          'diskon': diskon,
          'kuota': kuota,
          'tanggal_berlaku': tanggalBerlaku,
          'tanggal_expired': tanggalExpired,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> deletePromotion(String promotionId) async {
    try {
      final token = await SharedPrefHelper.getToken();

      final response = await http.delete(
        Uri.parse('${Api.baseUrl}/promotions/$promotionId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
  // --- FUNGSI MENGGUNAKAN (REDEEM) VOUCHER CUSTOMER ---
  Future<Map<String, dynamic>> useCustomerVoucher(String voucherId) async {
    try {
      final token = await SharedPrefHelper.getToken();

      final response = await http.put(
        Uri.parse('${Api.baseUrl}/customer-vouchers/use/$voucherId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
}