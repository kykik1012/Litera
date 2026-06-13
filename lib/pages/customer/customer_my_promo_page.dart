import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../constants/api.dart';
import '../../helpers/api_helper.dart';
import '../../helpers/shared_pref_helper.dart';
import '../../services/promotion_service.dart';
import '../../models/customer_voucher.dart';
import 'package:qr_flutter/qr_flutter.dart';

class CustomerMyPromoPage extends StatefulWidget {
  const CustomerMyPromoPage({super.key});

  @override
  State<CustomerMyPromoPage> createState() => _CustomerMyPromoPageState();
}

class _CustomerMyPromoPageState extends State<CustomerMyPromoPage> {
  final PromotionService _promotionService = PromotionService();
  
  List<CustomerVoucherModel> _allVouchers = [];
  bool _isLoading = true;
  String _myCustomerId = ""; // Menyimpan ID Customer Asli

  // Warna Tema Litera
  final Color darkGreen = const Color(0xFF003D33);
  final Color limeGreen = const Color(0xFFAEEA00);

  @override
  void initState() {
    super.initState();
    _fetchMyVouchers();
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

  Future<void> _fetchMyVouchers() async {
    setState(() => _isLoading = true);
    
    // 1. Tarik Customer ID terlebih dahulu
    await _getCustomerId();

    try {
      // 2. Tarik data voucher dari API
      final response = await _promotionService.getCustomerVouchers();
      
      if (response['success'] == true) {
        final List<dynamic> data = response['data'];
        
        setState(() {
          // Map data JSON ke Model, lalu filter menggunakan CUSTOMER ID (Bukan Nama)
          _allVouchers = data
              .map((json) => CustomerVoucherModel.fromJson(json))
              .where((v) => v.customerId == _myCustomerId)
              .toList();
        });
      }
    } catch (e) {
      debugPrint("Error loading my vouchers: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- FILTER VOUCHER TERSEDIA ---
  List<CustomerVoucherModel> get _activeVouchers {
    return _allVouchers.where((v) {
      bool isNotCancelled = v.status.toUpperCase() != 'CANCELLED';
      bool isNotUsed = v.usedAt == null;
      bool isNotExpired = v.tanggalExpired == null || DateTime.now().isBefore(v.tanggalExpired!);
      
      return isNotCancelled && isNotUsed && isNotExpired;
    }).toList();
  }

  // --- FILTER RIWAYAT VOUCHER ---
  List<CustomerVoucherModel> get _historyVouchers {
    return _allVouchers.where((v) {
      bool isCancelled = v.status.toUpperCase() == 'CANCELLED';
      bool isUsed = v.usedAt != null;
      bool isExpired = v.tanggalExpired != null && DateTime.now().isAfter(v.tanggalExpired!);
      
      return isCancelled || isUsed || isExpired;
    }).toList();
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dateTime);
  }

  void _copyToClipboard(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Kode voucher '$code' disalin!"),
        backgroundColor: darkGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showQrCodeDialog(String code, String namaToko, String namaProduk) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Tunjukkan QR ini ke Kasir",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkGreen),
              ),
              const SizedBox(height: 4),
              Text(
                "$namaToko - $namaProduk",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              
              // WIDGET QR CODE
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200, width: 2),
                ),
                child: QrImageView(
                  data: code, // Data yang akan diubah jadi QR (Kode Voucher)
                  version: QrVersions.auto,
                  size: 200.0,
                  foregroundColor: darkGreen, // Warna QR Code
                ),
              ),
              
              const SizedBox(height: 24),
              Text(
                code,
                style: TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold, 
                  letterSpacing: 4.0, 
                  color: darkGreen
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: limeGreen,
                    foregroundColor: darkGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text("Tutup", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7F8),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D3B2E),
          elevation: 0,
          toolbarHeight: 0,
        ),
        body: Column(
          children: [
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              "Voucher Saya",
                              style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Kelola semua voucher diskon yang kamu miliki di satu tempat",
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const TabBar(
                    labelColor: Color(0xFFAEEA00),
                    unselectedLabelColor: Colors.white70,
                    indicatorColor: Color(0xFFAEEA00),
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(text: "Tersedia"),
                      Tab(text: "Riwayat"),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      children: [
                        _buildVoucherList(_activeVouchers, isActive: true),
                        _buildVoucherList(_historyVouchers, isActive: false),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoucherList(List<CustomerVoucherModel> vouchers, {required bool isActive}) {
    if (vouchers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/data_kosong.png', height: 150),
            const SizedBox(height: 16),
            Text(
              isActive ? "Dompet Voucher Kosong" : "Belum Ada Riwayat",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkGreen),
            ),
            const SizedBox(height: 8),
            Text(
              isActive 
                  ? "Kamu belum mengklaim promo apa pun.\nCari promo menarik di menu utama!" 
                  : "Riwayat penggunaan vouchermu akan\nmuncul di sini.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchMyVouchers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: vouchers.length,
        itemBuilder: (context, index) {
          return _buildVoucherCard(vouchers[index], isActive: isActive);
        },
      ),
    );
  }

  Widget _buildVoucherCard(CustomerVoucherModel voucher, {required bool isActive}) {
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
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 90,
                height: 110,
                decoration: BoxDecoration(
                  color: isActive ? darkGreen : Colors.grey[400],
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(16)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "${voucher.diskon}%",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: isActive ? limeGreen : Colors.white,
                      ),
                    ),
                    const Text("OFF", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.orange[100] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          voucher.tipePromo.replaceAll('_', ' '),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isActive ? Colors.orange[800] : Colors.grey[600],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        voucher.namaBisnis,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: darkGreen),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "Berlaku untuk: ${voucher.namaProduk}",
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              voucher.tanggalExpired != null 
                                  ? "Hingga ${_formatDateTime(voucher.tanggalExpired!)}" 
                                  : "Tanpa batas waktu",
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
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
          
          Row(
            children: [
              SizedBox(
                height: 20,
                width: 10,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xFFF5F7F8),
                    borderRadius: BorderRadius.only(topRight: Radius.circular(10), bottomRight: Radius.circular(10)),
                  ),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Flex(
                      direction: Axis.horizontal,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.max,
                      children: List.generate(
                        (constraints.constrainWidth() / 10).floor(),
                        (index) => SizedBox(
                          width: 5, height: 1.5,
                          child: DecoratedBox(decoration: BoxDecoration(color: Colors.grey.shade300)),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(
                height: 20,
                width: 10,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xFFF5F7F8),
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)),
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("KODE VOUCHER", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(
                      voucher.voucherCode,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isActive ? darkGreen : Colors.grey,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),
                if (isActive)
                  Row(
                    children: [
                      // Tombol Salin
                      InkWell(
                        onTap: () => _copyToClipboard(voucher.voucherCode),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: limeGreen.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.copy, size: 16, color: darkGreen),
                              const SizedBox(width: 4),
                              Text("Salin", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: darkGreen)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      
                      // --- TOMBOL TAMPILKAN QR BARU ---
                      InkWell(
                        onTap: () => _showQrCodeDialog(voucher.voucherCode, voucher.namaBisnis, voucher.namaProduk),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: darkGreen,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.qr_code_2, size: 16, color: Colors.white),
                              const SizedBox(width: 4),
                              const Text("QR", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    voucher.status.toUpperCase(),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red[400]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}