import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../helpers/shared_pref_helper.dart';
import '../../services/user_service.dart';
import '../../services/product_service.dart';
import '../../models/product.dart';
import 'merchant_tambah_produk_page.dart';
import 'merchant_edit_katalog_page.dart';

class MerchantUsahaPage extends StatefulWidget {
  const MerchantUsahaPage({super.key});

  @override
  State<MerchantUsahaPage> createState() => _MerchantUsahaPageState();
}

class _MerchantUsahaPageState extends State<MerchantUsahaPage> {
  final UserService _userService = UserService();
  final ProductService _productService = ProductService();

  // Merchant info
  String _namaBisnis = '';
  String _deskripsi = '';
  String? _profilePicture;

  // Products
  List<ProductModel> _products = [];
  bool _isLoading = true;

  // Warna tema
  static const Color tealDark = Color(0xFF145C54);
  static const Color tealGradientEnd = Color(0xFF1A8A7A);
  static const Color limeGreen = Color(0xFFB8E926);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadMerchantProfile(),
      _loadProducts(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadMerchantProfile() async {
    try {
      final userId = await SharedPrefHelper.getUserId() ?? 0;
      if (userId == 0) return;

      final response = await _userService.getUserById(userId);
      if (response["success"] == true) {
        final data = response["data"];
        _namaBisnis = data["nama_bisnis"] ?? data["name"] ?? '';
        _deskripsi = data["deskripsi"] ?? '';
        _profilePicture = data["profile_picture"];
      }
    } catch (e) {
      debugPrint("Error loading merchant profile: $e");
    }
  }

  Future<void> _loadProducts() async {
    try {
      final response = await _productService.getAllProducts();
      if (response["success"] == true && response["data"] != null) {
        final List data = response["data"];
        
        // Ambil nama bisnis merchant yang sedang login
        final userId = await SharedPrefHelper.getUserId() ?? 0;
        String? currentMerchantName;
        
        if (userId != 0) {
          try {
            final userResponse = await _userService.getUserById(userId);
            if (userResponse["success"] == true) {
              currentMerchantName = userResponse["data"]["nama_bisnis"];
            }
          } catch (_) {}
        }

        final allProducts = data.map((json) => ProductModel.fromJson(json)).toList();
        
        // Filter produk milik merchant yang sedang login berdasarkan nama_bisnis
        if (currentMerchantName != null && currentMerchantName.isNotEmpty) {
          _products = allProducts
              .where((p) => p.namaBisnis == currentMerchantName)
              .toList();
        } else {
          _products = allProducts;
        }
      }
    } catch (e) {
      debugPrint("Error loading products: $e");
    }
  }

  void _navigateToAddProduct() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MerchantTambahProdukPage()),
    );

    // Refresh jika produk berhasil ditambahkan
    if (result == true) {
      _loadData();
    }
  }

  String _formatCurrency(num price) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(price);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100),
        child: FloatingActionButton(
          onPressed: _navigateToAddProduct,
          backgroundColor: limeGreen,
          shape: const CircleBorder(),
          child: const Icon(
            Icons.add,
            color: tealDark,
            size: 32,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: tealDark))
          : RefreshIndicator(
              color: tealDark,
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Card Profil Merchant ──
                      _buildMerchantCard(),
                      const SizedBox(height: 24),

                      // ── Header Katalog ──
                      _buildCatalogHeader(),
                      const SizedBox(height: 16),

                      // ── Daftar Produk atau Empty State ──
                      _products.isEmpty
                          ? _buildEmptyState()
                          : _buildProductList(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // ─── Card Profil Merchant ───
  Widget _buildMerchantCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [tealDark, tealGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: tealDark.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                // Ikon Merchant
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: _profilePicture != null
                      ? ClipOval(
                          child: Image.network(
                            _profilePicture!,
                            fit: BoxFit.cover,
                            width: 52,
                            height: 52,
                            errorBuilder: (c, e, s) => const Icon(
                              Icons.storefront_rounded,
                              color: Colors.white70,
                              size: 28,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.storefront_rounded,
                          color: Colors.white70,
                          size: 28,
                        ),
                ),
                const SizedBox(width: 14),
                // Nama & Deskripsi Merchant
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _namaBisnis.isEmpty ? 'Nama Merchant' : _namaBisnis,
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _deskripsi.isEmpty ? 'Alamat Merchant' : _deskripsi,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Colors.white70,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Tombol Edit Profil Usaha
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Navigate to edit merchant profile
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: tealDark,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Edit Profil Usaha',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header Katalog ───
  Widget _buildCatalogHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Katalog Saya',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A2E),
          ),
        ),
        GestureDetector(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MerchantEditKatalogPage(),
              ),
            );
            _loadData(); // Refresh data after returning
          },
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.edit_outlined,
              color: tealDark,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Empty State (Ketika Belum Ada Produk) ───
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ilustrasi placeholder
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 80,
                color: Colors.grey[300],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Kamu Belum Punya Produk',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Klik tanda + untuk menambahkan produk pada\ntoko Anda',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Daftar Produk ───
  Widget _buildProductList() {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: _products.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildProductCard(_products[index]);
      },
    );
  }

  // ─── Card Produk ───
  Widget _buildProductCard(ProductModel product) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          // Gambar Produk
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(14),
              bottomLeft: Radius.circular(14),
            ),
            child: SizedBox(
              width: 110,
              height: 100,
              child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                  ? Image.network(
                      product.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.fastfood_rounded,
                          color: Colors.grey[400],
                          size: 36,
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.fastfood_rounded,
                        color: Colors.grey[400],
                        size: 36,
                      ),
                    ),
            ),
          ),
          // Detail Produk
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    product.namaProduk,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A2E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.deskripsi,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[500],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatCurrency(product.hargaProduk),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: product.isAvailable
                              ? const Color(0xFF10B981).withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          product.isAvailable ? 'Tersedia' : 'Habis',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: product.isAvailable
                                ? const Color(0xFF10B981)
                                : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
