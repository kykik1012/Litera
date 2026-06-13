import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../helpers/shared_pref_helper.dart';
import '../../constants/api.dart';
import '../../helpers/api_helper.dart';
import '../../services/promotion_service.dart';
import '../../models/promotion.dart';

class CustomerPromoPage extends StatefulWidget {
  const CustomerPromoPage({super.key});

  @override
  State<CustomerPromoPage> createState() => _CustomerPromoPageState();
}

class _CustomerPromoPageState extends State<CustomerPromoPage> {
  final PromotionService _promotionService = PromotionService();
  
  List<PromotionModel> _promotions = [];
  bool _isLoading = true;
  String _myCustomerId = ""; // Menyimpan ID Customer Asli

  // Warna Tema Litera
  final Color darkGreen = const Color(0xFF003D33);
  final Color limeGreen = const Color(0xFFAEEA00);

  @override
  void initState() {
    super.initState();
    _fetchPromotions();
  }

  // --- FUNGSI MENCARI CUSTOMER ID ASLI ---
  Future<void> _getCustomerId() async {
    final int userId = await SharedPrefHelper.getUserId() ?? 0;
    if (userId == 0) return;

    try {
      final res = await http.get(Uri.parse("${Api.baseUrl}/customers"), headers: await ApiHelper.authHeaders());
      final data = jsonDecode(res.body);
      
      if (data['success'] == true) {
        final List<dynamic> customers = data['data'];
        final myData = customers.firstWhere(
          (c) => c['user_id'].toString() == userId.toString(),
          orElse: () => null,
        );
        if (myData != null) {
          _myCustomerId = myData['id'].toString();
        }
      }
    } catch (e) {
      debugPrint("Gagal mencari Customer ID: $e");
    }
  }

  // --- FUNGSI MENGAMBIL DATA PROMO ---
  Future<void> _fetchPromotions() async {
    setState(() => _isLoading = true);
    
    // Pastikan mencari Customer ID dulu sebelum mengambil promo
    await _getCustomerId();

    try {
      final response = await _promotionService.getAllPromotions();
      
      if (response['success'] == true) {
        final List<dynamic> data = response['data'];
        setState(() {
          _promotions = data.map((json) => PromotionModel.fromJson(json)).toList();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Gagal mengambil data promo')),
        );
      }
    } catch (e) {
      debugPrint("Error loading promotions: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- FUNGSI KLAIM VOUCHER ---
  Future<void> _claimVoucher(PromotionModel promo) async {
    // 1. Cek apakah pengguna sudah memiliki Customer ID
    if (_myCustomerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Data akun tidak lengkap. Gagal mengklaim.")),
      );
      return;
    }

    // 2. Munculkan Dialog Konfirmasi
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Klaim Voucher"),
        content: Text("Apakah kamu yakin ingin mengklaim diskon ${promo.diskon}% untuk produk ${promo.namaProduk}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: limeGreen,
              foregroundColor: darkGreen,
              elevation: 0,
            ),
            child: const Text("Klaim Sekarang"),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    // 3. Tampilkan loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    // 4. Panggil API Claim
    try {
      final res = await _promotionService.claimPromotion(
        customerId: int.parse(_myCustomerId),
        promotionId: int.parse(promo.id),
      );

      // Tutup loading overlay
      if (!mounted) return;
      Navigator.pop(context);

      // 5. Cek Hasilnya
      if (res['success'] == true) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.check_circle, color: limeGreen, size: 28),
                const SizedBox(width: 8),
                Text("Berhasil!", style: TextStyle(color: darkGreen)),
              ],
            ),
            content: Text("Hore! Voucher diskon ${promo.diskon}% berhasil diklaim dan masuk ke dompetmu."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text("Tutup", style: TextStyle(color: darkGreen, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
        // Refresh daftar promo (karena kuota di backend pasti berkurang 1)
        _fetchPromotions();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Gagal mengklaim voucher')));
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Tutup loading jika error
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Terjadi kesalahan jaringan: $e')));
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D3B2E),
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: Column(
        children: [
          // Header Estetik
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D3B2E), Color(0xFF1A8A7A)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Promo & Diskon",
                  style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Klaim voucher dan nikmati potongan harga khusus untukmu",
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          // Body List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _promotions.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _fetchPromotions,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _promotions.length,
                          itemBuilder: (context, index) {
                            return _buildPromoCard(_promotions[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_offer_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            "Belum Ada Promo",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkGreen),
          ),
          const SizedBox(height: 8),
          const Text(
            "Saat ini merchant belum memberikan promo.\nCek lagi nanti ya!",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCard(PromotionModel promo) {
    final bool canClaim = promo.isValid;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // BAGIAN KIRI: DISKON (Warna Hijau)
          Container(
            width: 100,
            height: 155, 
            decoration: BoxDecoration(
              color: canClaim ? darkGreen : Colors.grey[400],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "${promo.diskon}%",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: canClaim ? limeGreen : Colors.white,
                  ),
                ),
                const Text(
                  "OFF",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // BAGIAN KANAN: DETAIL PROMO
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: canClaim ? Colors.orange[100] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          promo.tipePromo.replaceAll('_', ' '),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: canClaim ? Colors.orange[800] : Colors.grey[600],
                          ),
                        ),
                      ),
                      Text(
                        promo.kuota > 0 ? "Sisa: ${promo.kuota}" : "Habis",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: promo.kuota > 0 ? darkGreen : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Text(
                    promo.namaBisnis,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: darkGreen),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    "Berlaku untuk: ${promo.namaProduk}",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const Divider(),

                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          promo.tanggalExpired != null 
                              ? "Hingga ${_formatDateTime(promo.tanggalExpired!)}" 
                              : "Tanpa batas waktu",
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ),
                      
                      // --- TOMBOL KLAIM ---
                      SizedBox(
                        height: 28,
                        child: ElevatedButton(
                          onPressed: canClaim ? () => _claimVoucher(promo) : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: limeGreen,
                            foregroundColor: darkGreen,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text("Klaim", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}