import 'package:flutter/material.dart';
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
        title: const Text("Hapus dari Rute?"),
        content: Text("Apakah Anda yakin ingin menghapus '$namaBisnis' dari rute ini?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Hapus", style: TextStyle(color: Colors.white)),
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
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Detail Lokasi Rute", style: TextStyle(fontSize: 18)),
            Text(
              widget.judulRute,
              style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredDetails.isEmpty
              ? const Center(child: Text("Belum ada lokasi merchant di rute ini."))
              : ListView.builder(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
                  itemCount: _filteredDetails.length,
                  itemBuilder: (context, index) {
                    final detail = _filteredDetails[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF003D33),
                          child: Text(
                            "${index + 1}",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          detail.namaBisnis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text("Lat: ${detail.latitude}\nLng: ${detail.longitude}"),
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
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_location_alt_rounded),
          label: const Text("Tambah Toko"),
        ),
      ),
    );
  }
}