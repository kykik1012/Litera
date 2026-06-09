import 'package:flutter/material.dart';
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
      appBar: AppBar(
        title: const Text("Kelola Review"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _merchants.isEmpty
              ? const Center(child: Text("Belum ada data merchant."))
              : ListView.builder(
                  // Padding 120 di bawah agar tidak tertutup navbar melayang
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
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
                        subtitle: const Text("Lihat daftar ulasan"),
                        trailing: const Icon(Icons.chevron_right),
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