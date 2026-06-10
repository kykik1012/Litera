import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:litera/models/route_detail.dart';
import '../../models/user_model.dart';
import '../../services/route_detail_service.dart';
import '../../services/user_service.dart';

// 1. TAMBAHKAN IMPORT INI
import 'tambah_rute_detail.dart'; 

class KelolaRuteDetailPage extends StatefulWidget {
  final int thematicRouteId;
  final String judulRute;

  const KelolaRuteDetailPage({
    super.key,
    required this.thematicRouteId,
    required this.judulRute,
  });

  @override
  State<KelolaRuteDetailPage> createState() => _KelolaRuteDetailPageState();
}

class _KelolaRuteDetailPageState extends State<KelolaRuteDetailPage> {
  final RouteDetailService _routeDetailService = RouteDetailService();
  final UserService _userService = UserService();

  List<RouteDetailModel> _filteredDetails = [];
  bool _isLoading = true;

  static const Color tealDark = Color(0xFF145C54);
  static const Color limeGreen = Color(0xFFB8E926);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Mengambil data detail rute
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final detailResponse = await _routeDetailService.getAllRouteDetails();
      if (detailResponse['success'] == true) {
        final List<dynamic> detailsData = detailResponse['data'];
        
        setState(() {
          _filteredDetails = detailsData
              .map((json) => RouteDetailModel.fromJson(json))
              .where((detail) => detail.thematicRouteId == widget.thematicRouteId)
              .toList();
        });
      }
    } catch (e) {
      debugPrint("Error load data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Menghapus merchant dari rute tematik ini
  Future<void> _deleteDetail(String id, String namaBisnis) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Hapus dari Rute?", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text("Apakah Anda yakin ingin menghapus '$namaBisnis' dari rute ini?", style: GoogleFonts.poppins()),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Batal", style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text("Hapus", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    try {
      final response = await _routeDetailService.deleteRouteDetail(id);
      if (response['success'] == true) {
        _loadData(); // Refresh data
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Berhasil menghapus lokasi dari rute!")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menghapus: $e")),
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Detail Lokasi Rute", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A2E))),
            Text(
              widget.judulRute,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: tealDark))
          : _filteredDetails.isEmpty
              ? Center(child: Text("Belum ada lokasi merchant di rute ini.", style: GoogleFonts.poppins(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
                  itemCount: _filteredDetails.length,
                  itemBuilder: (context, index) {
                    final detail = _filteredDetails[index];
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
                          backgroundColor: tealDark,
                          child: Text(
                            "${index + 1}",
                            style: GoogleFonts.poppins(color: limeGreen, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          detail.namaBisnis,
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF1A1A2E)),
                        ),
                        subtitle: Text("Lat: ${detail.latitude}\nLng: ${detail.longitude}", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
                          onPressed: () => _deleteDetail(detail.id, detail.namaBisnis),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70), 
        child: FloatingActionButton.extended(
          // 2. UBAH ON PRESSED INI
          onPressed: _isLoading ? null : () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TambahRuteDetailPage(
                  thematicRouteId: widget.thematicRouteId,
                ),
              ),
            );

            // Refresh jika sukses
            if (result == true) {
              _loadData();
            }
          },
          backgroundColor: tealDark,
          foregroundColor: limeGreen,
          icon: const Icon(Icons.add_location_alt_rounded),
          label: Text("Tambah Toko", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}