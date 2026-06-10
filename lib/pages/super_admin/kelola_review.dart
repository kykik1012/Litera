import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:litera/models/merchant.dart';
import '../../services/merchant_service.dart';

// Import halaman detail (buat file ini di langkah selanjutnya)
import 'kelola_detail_merchant_review.dart'; 

class KelolaReviewPage extends StatefulWidget {
  const KelolaReviewPage({super.key});

  @override
  State<KelolaReviewPage> createState() => _KelolaReviewPageState();
}

class _KelolaReviewPageState extends State<KelolaReviewPage> {
  final MerchantService _merchantService = MerchantService();
  
  List<MerchantModel> _merchants = [];
  bool _isLoading = true;

  static const Color tealDark = Color(0xFF145C54);
  static const Color limeGreen = Color(0xFFB8E926);

  @override
  void initState() {
    super.initState();
    _fetchMerchants();
  }

  Future<void> _fetchMerchants() async {
    setState(() => _isLoading = true);
    try {
      final response = await _merchantService.getAllMerchants();
      if (response['success'] == true) {
        final List<dynamic> data = response['data'];
        setState(() {
          _merchants = data.map((json) => MerchantModel.fromJson(json)).toList();
        });
      }
    } catch (e) {
      debugPrint("Error fetching merchants: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          "Kelola Review",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A1A2E),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: tealDark))
          : _merchants.isEmpty
              ? Center(child: Text("Belum ada data merchant.", style: GoogleFonts.poppins(color: Colors.grey)))
              : ListView.builder(
                  // Padding 120 di bawah agar tidak tertutup navbar melayang
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
                  itemCount: _merchants.length,
                  itemBuilder: (context, index) {
                    final merchant = _merchants[index];
                    
                    return Card(
                      elevation: 0,
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: limeGreen.withValues(alpha: 0.3),
                          child: const Icon(Icons.storefront, color: tealDark),
                        ),
                        title: Text(
                          merchant.namaBisnis,
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF1A1A2E)),
                        ),
                        subtitle: Text("Lihat daftar ulasan", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                        trailing: const Icon(Icons.chevron_right, color: tealDark),
                        onTap: () {
                          // Arahkan ke halaman detail review milik merchant ini
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => KelolaDetailMerchantReviewPage(
                                merchantId: merchant.id, // Kirim ID Merchant
                                namaBisnis: merchant.namaBisnis, // Kirim Nama Bisnis
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}