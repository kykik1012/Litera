import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:litera/models/merchant.dart';
import '../../services/merchant_service.dart';
import '../../services/route_detail_service.dart';

class TambahRuteDetailPage extends StatefulWidget {
  final int thematicRouteId;

  const TambahRuteDetailPage({
    super.key,
    required this.thematicRouteId,
  });

  @override
  State<TambahRuteDetailPage> createState() => _TambahRuteDetailPageState();
}

class _TambahRuteDetailPageState extends State<TambahRuteDetailPage> {
  final MerchantService _merchantService = MerchantService();
  final RouteDetailService _routeDetailService = RouteDetailService();

  List<MerchantModel> _merchants = [];
  bool _isLoading = true;

  static const Color tealDark = Color(0xFF145C54);
  static const Color limeGreen = Color(0xFFB8E926);

  @override
  void initState() {
    super.initState();
    _fetchMerchants();
  }

  // Mengambil daftar merchant dari API
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

  // Aksi saat merchant dipilih
  Future<void> _addMerchantToRoute(MerchantModel merchant) async {
    // Tampilkan dialog konfirmasi
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Tambah ke Rute?", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text("Tambahkan '${merchant.namaBisnis}' ke dalam rute ini?", style: GoogleFonts.poppins()),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Batal", style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: tealDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text("Ya, Tambahkan", style: GoogleFonts.poppins(color: limeGreen, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    // Tampilkan loading overlay sementara API berjalan
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: limeGreen)),
    );

    try {
      final response = await _routeDetailService.createRouteDetail(
        merchantId: int.parse(merchant.id),
        thematicRouteId: widget.thematicRouteId,
      );

      // Tutup loading overlay
      Navigator.pop(context);

      if (response['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Merchant berhasil ditambahkan ke rute!")),
        );
        // Kembali ke halaman detail rute dan bawa sinyal "true" (sukses)
        Navigator.pop(context, true);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? "Gagal menambahkan")),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Tutup loading overlay
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Terjadi kesalahan: $e")),
      );
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1A1A2E), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          "Pilih Merchant",
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
              ? Center(child: Text("Tidak ada data merchant.", style: GoogleFonts.poppins(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
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
                        subtitle: Text(merchant.deskripsi ?? "Tidak ada deskripsi", maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                        trailing: const Icon(Icons.add_circle, color: tealDark),
                        onTap: () => _addMerchantToRoute(merchant),
                      ),
                    );
                  },
                ),
    );
  }
}