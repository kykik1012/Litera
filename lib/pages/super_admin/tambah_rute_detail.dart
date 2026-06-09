import 'package:flutter/material.dart';
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
        title: const Text("Tambah ke Rute?"),
        content: Text("Tambahkan '${merchant.namaBisnis}' ke dalam rute ini?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Ya, Tambahkan", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    // Tampilkan loading overlay sementara API berjalan
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.green)),
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
      appBar: AppBar(
        title: const Text("Pilih Merchant"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _merchants.isEmpty
              ? const Center(child: Text("Tidak ada data merchant."))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _merchants.length,
                  itemBuilder: (context, index) {
                    final merchant = _merchants[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.orange,
                          child: Icon(Icons.storefront, color: Colors.white),
                        ),
                        title: Text(
                          merchant.namaBisnis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(merchant.deskripsi ?? "Tidak ada deskripsi", maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: const Icon(Icons.add_circle, color: Colors.green),
                        onTap: () => _addMerchantToRoute(merchant),
                      ),
                    );
                  },
                ),
    );
  }
}