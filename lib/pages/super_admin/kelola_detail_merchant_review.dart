import 'package:flutter/material.dart';
import '../../models/review.dart'; // Sesuaikan nama file ini jika namanya review_model.dart
import '../../services/review_service.dart';

class KelolaDetailMerchantReviewPage extends StatefulWidget {
  final String merchantId;
  final String namaBisnis;

  const KelolaDetailMerchantReviewPage({
    super.key,
    required this.merchantId,
    required this.namaBisnis,
  });

  @override
  State<KelolaDetailMerchantReviewPage> createState() => _KelolaDetailMerchantReviewPageState();
}

class _KelolaDetailMerchantReviewPageState extends State<KelolaDetailMerchantReviewPage> {
  final ReviewService _reviewService = ReviewService();
  
  // 1. UBAH DI SINI: Review menjadi ReviewModel
  List<ReviewModel> _merchantReviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    setState(() => _isLoading = true);
    try {
      final response = await _reviewService.getAllReviews();
      if (response['success'] == true) {
        final List<dynamic> data = response['data'];
        setState(() {
          _merchantReviews = data
              // 2. UBAH DI SINI: Review.fromJson menjadi ReviewModel.fromJson
              .map((json) => ReviewModel.fromJson(json))
              .where((review) => review.namaBisnis.toLowerCase() == widget.namaBisnis.toLowerCase())
              .toList();
        });
      }
    } catch (e) {
      debugPrint("Error fetching reviews: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 3. UBAH DI SINI: Review menjadi ReviewModel
  Future<void> _handleAction(ReviewModel review) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(!review.isDelete ? "Hapus Ulasan?" : "Pulihkan Ulasan?"),
        content: Text("Apakah Anda yakin ingin ${!review.isDelete ? 'menghapus' : 'memulihkan'} ulasan dari ${review.customerName}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: !review.isDelete ? Colors.red : Colors.green,
            ),
            child: const Text("Ya, Lanjutkan", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    try {
      if (!review.isDelete) {
        await _reviewService.deleteReview(review.id);
      } else {
        await _reviewService.restoreReview(review.id);
      }
      _fetchReviews(); // Refresh data
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Berhasil mengubah status ulasan!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Terjadi kesalahan: $e")),
      );
    }
  }

  Widget _buildStarRating(num rating) {
    List<Widget> stars = [];
    for (int i = 1; i <= 5; i++) {
      stars.add(
        Icon(
          i <= rating ? Icons.star_rounded : Icons.star_border_rounded,
          color: Colors.amber,
          size: 20,
        ),
      );
    }
    return Row(children: stars);
  }

  // 4. UBAH DI SINI: List<Review> menjadi List<ReviewModel>
  Widget _buildReviewList(List<ReviewModel> reviews) {
    if (reviews.isEmpty) {
      return const Center(child: Text("Tidak ada ulasan untuk merchant ini."));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
      itemCount: reviews.length,
      itemBuilder: (context, index) {
        final review = reviews[index];

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review.customerName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        _buildStarRating(review.rating),
                      ],
                    ),
                    IconButton(
                      onPressed: () => _handleAction(review),
                      icon: Icon(
                        !review.isDelete ? Icons.delete_outline_rounded : Icons.restore_rounded,
                        color: !review.isDelete ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Text(
                  review.deskripsi,
                  style: TextStyle(color: Colors.grey[800], fontSize: 14),
                ),
                
                if (review.imageUrl != null && review.imageUrl!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      review.imageUrl!,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 150,
                          color: Colors.grey[200],
                          child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeReviews = _merchantReviews.where((r) => !r.isDelete).toList();
    final historyReviews = _merchantReviews.where((r) => r.isDelete).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Daftar Ulasan", style: TextStyle(fontSize: 18)),
              Text(
                widget.namaBisnis,
                style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.normal),
              ),
            ],
          ),
          bottom: const TabBar(
            labelColor: Colors.green,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.green,
            tabs: [
              Tab(text: "Ulasan Aktif"),
              Tab(text: "History"),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildReviewList(activeReviews),
                  _buildReviewList(historyReviews),
                ],
              ),
      ),
    );
  }
}