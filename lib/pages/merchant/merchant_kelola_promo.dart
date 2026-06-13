import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../helpers/shared_pref_helper.dart';
import '../../services/merchant_service.dart';
import '../../services/promotion_service.dart';
import '../../models/promotion.dart';
import 'merchant_daftar_voucher_page.dart';

// Import halaman baru untuk membuat promo
import 'merchant_tambah_promo_page.dart';

class MerchantKelolaPromoPage extends StatefulWidget {
  const MerchantKelolaPromoPage({super.key});

  @override
  State<MerchantKelolaPromoPage> createState() => _MerchantKelolaPromoPageState();
}

class _MerchantKelolaPromoPageState extends State<MerchantKelolaPromoPage> {
  final PromotionService _promotionService = PromotionService();
  final MerchantService _merchantService = MerchantService();

  List<PromotionModel> _myPromotions = [];
  bool _isLoading = true;
  String _myMerchantId = '';

  static const Color tealDark = Color(0xFF0D3B2E);
  static const Color limeGreen = Color(0xFFAEEA00);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final userId = await SharedPrefHelper.getUserId() ?? 0;
      if (userId == 0) return;

      // 1. Dapatkan Merchant ID dari user yang sedang login
      final merchantRes = await _merchantService.getAllMerchants();
      if (merchantRes['success'] == true) {
        final List<dynamic> mList = merchantRes['data'];
        final myMerchant = mList.firstWhere(
          (m) => m['user_id'].toString() == userId.toString(),
          orElse: () => null,
        );
        
        if (myMerchant != null) {
          _myMerchantId = myMerchant['id'].toString();
        }
      }

      // 2. Tarik semua promo, lalu filter khusus milik Merchant ini & belum dihapus
      if (_myMerchantId.isNotEmpty) {
        final promoRes = await _promotionService.getAllPromotions();
        if (promoRes['success'] == true) {
          final List<dynamic> pList = promoRes['data'];
          setState(() {
            _myPromotions = pList
                .map((json) => PromotionModel.fromJson(json))
                .where((p) => p.merchantId == _myMerchantId && !p.isDelete)
                .toList();
          });
        }
      }
    } catch (e) {
      debugPrint("Error memuat promo: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dateTime);
  }

  Future<void> _deletePromo(PromotionModel promo) async {
    // 1. Tampilkan Dialog Konfirmasi
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            const SizedBox(width: 8),
            Text("Hapus Promo", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          "Apakah Anda yakin ingin menghapus promo diskon ${promo.diskon}% untuk ${promo.namaProduk}?",
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("Batal", style: GoogleFonts.poppins(color: Colors.grey[600], fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text("Ya, Hapus", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    // 2. Munculkan loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.red)),
    );

    // 3. Panggil API Hapus
    try {
      final res = await _promotionService.deletePromotion(promo.id);

      if (!mounted) return;
      Navigator.pop(context); // Tutup loading

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Promo berhasil dihapus"), backgroundColor: Colors.green),
        );
        _loadData(); // Refresh daftar promo agar yang terhapus hilang
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? "Gagal menghapus promo"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            "Kelola Promo",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold, 
              fontSize: 22,
              color: tealDark,
            ),
          ),
        ),
      ),
      // --- TOMBOL TAMBAH PROMO ---
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 95.0),
        child: FloatingActionButton.extended(
          onPressed: () async {
            // Buka halaman tambah promo, tunggu sampai kembali
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MerchantTambahPromoPage()),
            );
            
            // Jika berhasil menambahkan, refresh halaman
            if (result == true) {
              _loadData();
            }
          },
          backgroundColor: limeGreen,
          elevation: 4,
          icon: const Icon(Icons.add, color: tealDark),
          label: Text(
            "Buat Promo",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: tealDark),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _myPromotions.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  color: tealDark,
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 160),
                    itemCount: _myPromotions.length,
                    itemBuilder: (context, index) {
                      return _buildPromoCard(_myPromotions[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.discount_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "Belum Ada Promo",
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: tealDark),
          ),
          const SizedBox(height: 8),
          Text(
            "Buat promo diskon untuk menarik\nlebih banyak pembeli!",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCard(PromotionModel promo) {
    final bool isAktif = promo.isValid;
    
    // --- BUNGKUS KARTU DENGAN GESTURE DETECTOR DI SINI ---
    return GestureDetector(
      onTap: () {
        // Navigasi ke halaman daftar pelanggan yang mengklaim voucher
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MerchantDaftarVoucherPage(promo: promo),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            // Blok Diskon Kiri
            Container(
              width: 100,
              height: 130,
              decoration: BoxDecoration(
                color: isAktif ? tealDark : Colors.grey[400],
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
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isAktif ? limeGreen : Colors.white,
                    ),
                  ),
                  Text(
                    "OFF",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            // Informasi Kanan
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isAktif ? Colors.orange[100] : Colors.grey[200],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            promo.tipePromo.replaceAll('_', ' '),
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isAktif ? Colors.orange[800] : Colors.grey[600],
                            ),
                          ),
                        ),
                        Text(
                          isAktif ? "Sisa: ${promo.kuota}" : "Habis/Expired",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isAktif ? tealDark : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      promo.namaProduk,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A1A2E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  promo.tanggalExpired != null 
                                      ? "Hingga ${_formatDateTime(promo.tanggalExpired!)}"
                                      : "Tanpa batas waktu",
                                  style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[600]), 
                                  maxLines: 1, 
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(width: 6), 
                        
                        // AREA TOMBOL AKSI
                        Row(
                          mainAxisSize: MainAxisSize.min, 
                          children: [
                            // TOMBOL EDIT
                            InkWell(
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MerchantTambahPromoPage(existingPromo: promo),
                                  ),
                                );
                                if (result == true) {
                                  _loadData();
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: tealDark.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.edit_outlined, size: 16, color: tealDark),
                              ),
                            ),

                            const SizedBox(width: 6), 
                                
                            // TOMBOL HAPUS
                            InkWell(
                              onTap: () => _deletePromo(promo),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}