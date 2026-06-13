import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../helpers/shared_pref_helper.dart';
import '../../services/review_service.dart';
import '../../services/user_service.dart';
import '../../services/merchant_service.dart';
import '../../models/review.dart';

class MerchantUlasanPage extends StatefulWidget {
  const MerchantUlasanPage({super.key});

  @override
  State<MerchantUlasanPage> createState() => _MerchantUlasanPageState();
}

class _MerchantUlasanPageState extends State<MerchantUlasanPage> {
  final ReviewService _reviewService = ReviewService();
  final UserService _userService = UserService();
  final MerchantService _merchantService = MerchantService();

  List<ReviewModel> _allReviews = [];
  bool _isLoading = true;
  String _namaBisnis = '';
  int _selectedTabIndex = 0; // 0: Semua, 1: Belum Dibalas, 2: Foto & Video

  // Colors matching the app theme
  static const Color tealDark = Color(0xFF0D3B2E);
  static const Color tealMid = Color(0xFF145C54);
  static const Color tealGradientEnd = Color(0xFF1A8A7A);
  static const Color limeGreen = Color(0xFFAEEA00);
  static const Color starYellow = Color(0xFFF59E0B);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final userId = await SharedPrefHelper.getUserId() ?? 0;
      if (userId != 0) {
        final merchantRes = await _merchantService.getAllMerchants();
        if (merchantRes['success'] == true) {
          final List<dynamic> mList = merchantRes['data'];
          final myMerchant = mList.firstWhere(
            (m) => m['user_id'].toString() == userId.toString(),
            orElse: () => null,
          );
          if (myMerchant != null) {
            _namaBisnis = myMerchant['nama_bisnis'] ?? '';
          }
        }
      }

      // 3. Tarik semua ulasan menggunakan nama bisnis yang sudah akurat
      if (_namaBisnis.isNotEmpty) {
        final reviewsData = await _reviewService.getReviewsByMerchantName(_namaBisnis);
        _allReviews = reviewsData.map((json) => ReviewModel.fromJson(json)).toList();
        // Sort by submitted_at descending (newest first)
        _allReviews.sort((a, b) {
          if (a.submittedAt == null && b.submittedAt == null) return 0;
          if (a.submittedAt == null) return 1;
          if (b.submittedAt == null) return -1;
          return b.submittedAt!.compareTo(a.submittedAt!);
        });
      } else {
         _allReviews = [];
      }
    } catch (e) {
      debugPrint("Error loading reviews: $e");
    }
    if (mounted) setState(() => _isLoading = false);
  }

  // Get filtered reviews based on selected tab
  List<ReviewModel> get _filteredReviews {
    switch (_selectedTabIndex) {
      case 1: // Belum Dibalas - all reviews (API doesn't have reply tracking)
        return _allReviews;
      case 2: // Foto & Video - only reviews with images
        return _allReviews.where((r) => r.imageUrl != null && r.imageUrl!.isNotEmpty).toList();
      default: // Semua
        return _allReviews;
    }
  }

  // Calculate average rating
  double get _averageRating {
    if (_allReviews.isEmpty) return 0;
    final total = _allReviews.fold<double>(0, (sum, r) => sum + r.rating.toDouble());
    return total / _allReviews.length;
  }

  // Count reviews per star rating
  Map<int, int> get _ratingDistribution {
    final dist = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final review in _allReviews) {
      final star = review.rating.toInt().clamp(1, 5);
      dist[star] = (dist[star] ?? 0) + 1;
    }
    return dist;
  }

  // Count reviews with photos
  int get _photoReviewCount {
    return _allReviews.where((r) => r.imageUrl != null && r.imageUrl!.isNotEmpty).length;
  }

  // Format relative time
  String _formatRelativeTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit yang lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam yang lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari yang lalu';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} minggu yang lalu';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} bulan yang lalu';
    return '${(diff.inDays / 365).floor()} tahun yang lalu';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: tealMid))
          : RefreshIndicator(
              color: tealMid,
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildRatingSummaryHeader(),
                    _buildTabFilters(),
                    _buildReviewsList(),
                    const SizedBox(height: 120), // Padding for bottom nav
                  ],
                ),
              ),
            ),
    );
  }

  // ═══════════════════════════════════════════
  // RATING SUMMARY HEADER (Green gradient card)
  // ═══════════════════════════════════════════
  Widget _buildRatingSummaryHeader() {
    final dist = _ratingDistribution;
    final maxCount = dist.values.fold(0, (max, val) => val > max ? val : max);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [tealDark, tealGradientEnd],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Left side: Average rating
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _averageRating.toStringAsFixed(1),
                      style: GoogleFonts.poppins(
                        fontSize: 42,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < _averageRating.round()
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: starYellow,
                          size: 18,
                        );
                      }),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${NumberFormat('#,###').format(_allReviews.length)} Ulasan',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                // Right side: Rating distribution bars
                Expanded(
                  child: Column(
                    children: [5, 4, 3, 2, 1].map((star) {
                      final count = dist[star] ?? 0;
                      final ratio = maxCount > 0 ? count / maxCount : 0.0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.5),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 12,
                              child: Text(
                                '$star',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Stack(
                                children: [
                                  Container(
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: ratio,
                                    child: Container(
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: limeGreen,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 32,
                              child: Text(
                                '$count',
                                textAlign: TextAlign.right,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // TAB FILTERS
  // ═══════════════════════════════════════════
  Widget _buildTabFilters() {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          _buildTabChip('Semua', 0, null),
          const SizedBox(width: 10),
          _buildTabChip('Foto', 2, _photoReviewCount),
        ],
      ),
    );
  }

  Widget _buildTabChip(String label, int index, int? badgeCount) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? tealDark : Colors.grey[500],
            ),
          ),
          if (badgeCount != null && badgeCount > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? tealDark : Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$badgeCount',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // REVIEWS LIST
  // ═══════════════════════════════════════════
  Widget _buildReviewsList() {
    final reviews = _filteredReviews;

    if (reviews.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: reviews.length,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemBuilder: (context, index) => _buildReviewCard(reviews[index]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.rate_review_outlined,
                size: 36,
                color: Colors.grey[300],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada ulasan',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ulasan pelanggan akan muncul di sini',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // INDIVIDUAL REVIEW CARD
  // ═══════════════════════════════════════════
  Widget _buildReviewCard(ReviewModel review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: Avatar, Name, Time, Rating
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.person,
                    color: Colors.grey[400],
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Name and time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.customerName,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatRelativeTime(review.submittedAt),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              // Star rating
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_rounded, color: starYellow, size: 18),
                  const SizedBox(width: 2),
                  Text(
                    review.rating.toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Review text
          Text(
            review.deskripsi,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),

          // Review image (if any)
          if (review.imageUrl != null && review.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 12),
            
            // --- TAMBAHKAN GESTURE DETECTOR DI SINI ---
            GestureDetector(
              onTap: () {
                // Memunculkan Pop-up Gambar Full Screen
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return Dialog(
                      backgroundColor: Colors.transparent, // Background transparan
                      insetPadding: EdgeInsets.zero, // Hilangkan batas pinggir agar full screen
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 1. Background Hitam Transparan (Bisa diklik untuk menutup)
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: double.infinity,
                              height: double.infinity,
                              color: Colors.black87,
                            ),
                          ),
                          // 2. Widget Gambar yang bisa di-Zoom
                          InteractiveViewer(
                            panEnabled: true, // Bisa digeser saat di-zoom
                            minScale: 0.5,
                            maxScale: 4.0, // Batas maksimal zoom
                            child: Image.network(
                              review.imageUrl!,
                              fit: BoxFit.contain, // Tampilkan seluruh gambar tanpa terpotong
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                          // 3. Tombol Silang (Tutup) di Pojok Kanan Atas
                          Positioned(
                            top: 40,
                            right: 20,
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white, size: 32),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              // Tampilan Gambar Kecil di dalam List
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  review.imageUrl!,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(Icons.broken_image_outlined, 
                        color: Colors.grey[400], size: 32),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}