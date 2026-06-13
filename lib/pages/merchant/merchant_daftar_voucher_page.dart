import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../services/promotion_service.dart';
import '../../models/promotion.dart';
import '../../models/customer_voucher.dart';



// Import halaman scanner yang baru kita buat
import 'merchant_scan_voucher_page.dart';

class MerchantDaftarVoucherPage extends StatefulWidget {
  final PromotionModel promo;
  const MerchantDaftarVoucherPage({super.key, required this.promo});

  @override
  State<MerchantDaftarVoucherPage> createState() => _MerchantDaftarVoucherPageState();
}

class _MerchantDaftarVoucherPageState extends State<MerchantDaftarVoucherPage> {
  final PromotionService _promotionService = PromotionService();
  List<CustomerVoucherModel> _vouchers = [];
  bool _isLoading = true;

  final Color darkGreen = const Color(0xFF003D33);
  final Color limeGreen = const Color(0xFFAEEA00);

  @override
  void initState() {
    super.initState();
    _loadVouchers();
  }

  Future<void> _loadVouchers() async {
    setState(() => _isLoading = true);
    try {
      final response = await _promotionService.getCustomerVouchers();
      if (response['success'] == true) {
        final List<dynamic> data = response['data'];
        setState(() {
          // Filter voucher yang hanya berasal dari ID Promo ini saja
          _vouchers = data
              .map((json) => CustomerVoucherModel.fromJson(json))
              // Asumsi model CustomerVoucherModel memiliki variabel tipePromo atau ID promo, 
              // Jika API tidak memberikan promotion_id di getCustomerVouchers, kita memfilter dari nama_produk & diskon
              .where((v) => v.namaProduk == widget.promo.namaProduk && v.diskon == widget.promo.diskon)
              .toList();
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- LOGIKA SCAN & UPDATE STATUS ---
  Future<void> _scanAndUpdateVoucher() async {
    // 1. Buka Scanner dan tunggu hasil kode dari QR
    final scannedCode = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MerchantScanVoucherPage()),
    );

    if (scannedCode == null || scannedCode.toString().isEmpty) return;

    // 2. Cari apakah kode yang discan ada di dalam daftar voucher promo ini
    final targetVoucher = _vouchers.firstWhere(
      (v) => v.voucherCode == scannedCode,
      orElse: () => CustomerVoucherModel(id: '', customerId: '', merchantId: '', voucherCode: '', status: 'NOT_FOUND', customerName: '', tipePromo: '', diskon: 0, namaProduk: '', namaBisnis: ''),
    );

    if (targetVoucher.id.isEmpty) {
      _showSnackBar("Voucher tidak ditemukan untuk promo ini!", Colors.red);
      return;
    }

    if (targetVoucher.status.toUpperCase() == 'USED' || targetVoucher.usedAt != null) {
      _showSnackBar("Voucher ini sudah pernah digunakan!", Colors.orange);
      return;
    }

    // 3. Tampilkan Loading & Tembak API Update (USE)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await _promotionService.useCustomerVoucher(targetVoucher.id);
      
      if (!mounted) return;
      Navigator.pop(context); // Tutup Loading

      if (response['success'] == true) {
        _showSnackBar("Voucher berhasil digunakan!", Colors.green);
        _loadVouchers(); // Refresh daftar agar statusnya berubah jadi USED
      } else {
        _showSnackBar(response['message'] ?? "Gagal menggunakan voucher", Colors.red);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showSnackBar("Terjadi kesalahan: $e", Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '-';
    return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: darkGreen,
        foregroundColor: Colors.white,
        title: Text("Voucher Diklaim", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      // --- TOMBOL SCANNER MELAYANG ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scanAndUpdateVoucher,
        backgroundColor: limeGreen,
        foregroundColor: darkGreen,
        icon: const Icon(Icons.qr_code_scanner),
        label: Text("Scan Voucher", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _vouchers.isEmpty
              ? Center(child: Text("Belum ada pelanggan yang mengklaim.", style: GoogleFonts.poppins(color: Colors.grey)))
              : RefreshIndicator(
                  onRefresh: _loadVouchers,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _vouchers.length,
                    itemBuilder: (context, index) {
                      final v = _vouchers[index];
                      bool isUsed = v.status.toUpperCase() == 'USED' || v.usedAt != null;

                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: isUsed ? Colors.grey[300] : Colors.orange[100],
                            child: Icon(Icons.person, color: isUsed ? Colors.grey : Colors.orange),
                          ),
                          title: Text(v.customerName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Kode: ${v.voucherCode}", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                              if (isUsed)
                                Text("Digunakan: ${_formatDateTime(v.usedAt)}", style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isUsed ? Colors.grey[300] : limeGreen.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isUsed ? "TERPAKAI" : "TERSEDIA",
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isUsed ? Colors.grey[600] : darkGreen,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}