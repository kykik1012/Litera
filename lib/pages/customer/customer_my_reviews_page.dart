import 'package:flutter/material.dart';
import '../../models/review.dart';
import '../../services/review_service.dart';
import '../../helpers/shared_pref_helper.dart';
import '../../services/user_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../constants/api.dart';
import '../../helpers/api_helper.dart';

// Import halaman edit yang akan kita buat di langkah 4

class CustomerMyReviewsPage extends StatefulWidget {
  const CustomerMyReviewsPage({super.key});

  @override
  State<CustomerMyReviewsPage> createState() => _CustomerMyReviewsPageState();
}

class _CustomerMyReviewsPageState extends State<CustomerMyReviewsPage> {
  final ReviewService _reviewService = ReviewService();
  List<ReviewModel> _myReviews = [];
  bool _isLoading = true;

  final Color darkGreen = const Color(0xFF003D33);
  final Color limeGreen = const Color(0xFFAEEA00);

  @override
  void initState() {
    super.initState();
    _fetchMyReviews();
  }

  Future<void> _fetchMyReviews() async {
    setState(() => _isLoading = true);
    
    try {
      // 1. Ambil User ID dari sesi login saat ini
      final int myUserId = await SharedPrefHelper.getUserId() ?? 0;
      String myCustomerId = "";

      // 2. PROSES PERTAMA: Wajib mencari tahu Customer ID dari backend
      if (myUserId != 0) {
        final customerRes = await http.get(
          Uri.parse("${Api.baseUrl}/customers"), // Panggil API Customers
          headers: await ApiHelper.authHeaders(),
        );
        final customerData = jsonDecode(customerRes.body);
        
        if (customerData['success'] == true) {
          final List<dynamic> customersList = customerData['data'];
          
          // Cari profil customer yang user_id-nya cocok dengan akun yang sedang login
          final myProfile = customersList.firstWhere(
            (c) => c['user_id'].toString() == myUserId.toString(),
            orElse: () => null,
          );
          
          if (myProfile != null) {
            myCustomerId = myProfile['id'].toString(); // Inilah Customer ID aslinya
          }
        }
      }

      // --- ATURAN BLOKIR ---
      // Jika Customer ID tidak ditemukan, langsung hentikan fungsi di sini.
      // (Karena kalau belum jadi Customer, mustahil punya ulasan).
      if (myCustomerId.isEmpty) {
        setState(() {
          _myReviews = [];
          _isLoading = false;
        });
        return; 
      }

      // 3. PROSES KEDUA: Setelah Customer ID pasti di tangan, baru ambil ulasan
      final response = await _reviewService.getAllReviews();
      if (response['success'] == true) {
        final List<dynamic> data = response['data'];
        
        setState(() {
          // 4. Saring dengan sangat ketat (Hanya ambil jika customerId persis sama dengan myCustomerId)
          _myReviews = data
              .map((json) => ReviewModel.fromJson(json))
              .where((review) => !review.isDelete && review.customerId == myCustomerId) 
              .toList();
        });
      }
    } catch (e) {
      debugPrint("Gagal mengambil ulasan saya: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- FUNGSI MENGHAPUS ULASAN ---
  Future<void> _deleteReview(String reviewId) async {
    // Tampilkan Dialog Konfirmasi Terlebih Dahulu
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Ulasan"),
        content: const Text("Yakin ingin menghapus ulasan ini?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Hapus", style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    setState(() => _isLoading = true);
    try {
      final response = await _reviewService.deleteReview(reviewId);
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ulasan berhasil dihapus"), backgroundColor: Colors.green));
        _fetchMyReviews(); // Refresh daftar ulasan
      } else {
        throw Exception(response['message'] ?? 'Gagal menghapus');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e")));
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        backgroundColor: darkGreen,
        foregroundColor: Colors.white,
        title: const Text("Review Saya"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _myReviews.isEmpty
              ? const Center(child: Text("Kamu belum pernah menulis ulasan."))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _myReviews.length,
                  itemBuilder: (context, index) {
                    final review = _myReviews[index];
                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header: Nama Toko & Rating
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.storefront, color: darkGreen, size: 20),
                                    const SizedBox(width: 8),
                                    Text(review.namaBisnis, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: darkGreen)),
                                  ],
                                ),
                                Row(
                                  children: List.generate(5, (i) => Icon(
                                    i < review.rating ? Icons.star_rounded : Icons.star_border_rounded,
                                    color: Colors.amber, size: 16,
                                  )),
                                )
                              ],
                            ),
                            const Divider(height: 24),
                            
                            // Konten Ulasan
                            Text(review.deskripsi, style: TextStyle(color: Colors.grey[800])),
                            
                            if (review.imageUrl != null && review.imageUrl!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(review.imageUrl!, width: 100, height: 100, fit: BoxFit.cover),
                              ),
                            ],
                            
                            const SizedBox(height: 16),
                            
                            // Tombol Edit dan Hapus
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _deleteReview(review.id),
                                  icon: const Icon(Icons.delete, size: 16),
                                  label: const Text("Hapus"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade50,
                                    foregroundColor: Colors.red,
                                    elevation: 0,
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}