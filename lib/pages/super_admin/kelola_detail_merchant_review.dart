import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/review.dart';
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
  
  List<ReviewModel> _merchantReviews = [];
  bool _isLoading = true;

  static const Color tealDark = Color(0xFF145C54);
  static const Color limeGreen = Color(0xFFB8E926);

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
        title: Text(!review.isDelete ? "Hapus Ulasan?" : "Pulihkan Ulasan?", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text("Apakah Anda yakin ingin ${!review.isDelete ? 'menghapus' : 'memulihkan'} ulasan dari ${review.customerName}?", style: GoogleFonts.poppins()),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Batal", style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: !review.isDelete ? Colors.red : limeGreen,
              foregroundColor: !review.isDelete ? Colors.white : tealDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text("Ya, Lanjutkan", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
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
      return Center(child: Text("Tidak ada ulasan untuk merchant ini.", style: GoogleFonts.poppins(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
      itemCount: reviews.length,
      itemBuilder: (context, index) {
        final review = reviews[index];

        return Card(
          elevation: 0,
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
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
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF1A1A2E)),
                        ),
                        const SizedBox(height: 4),
                        _buildStarRating(review.rating),
                      ],
                    ),
                    IconButton(
                      onPressed: () => _handleAction(review),
                      icon: Icon(
                        !review.isDelete ? Icons.delete_outline_rounded : Icons.restore_rounded,
                        color: !review.isDelete ? Colors.red : tealDark,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20, color: Color(0xFFEEEEEE)),
                Text(
                  review.deskripsi,
                  style: GoogleFonts.poppins(color: Colors.grey[800], fontSize: 14),
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
              Text("Daftar Ulasan", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A2E))),
              Text(
                widget.namaBisnis,
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.normal),
              ),
            ],
          ),
          bottom: TabBar(
            labelColor: tealDark,
            unselectedLabelColor: Colors.grey,
            indicatorColor: limeGreen,
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            unselectedLabelStyle: GoogleFonts.poppins(),
            tabs: const [
              Tab(text: "Ulasan Aktif"),
              Tab(text: "History"),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: tealDark))
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