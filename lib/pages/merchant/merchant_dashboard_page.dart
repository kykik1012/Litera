import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../helpers/shared_pref_helper.dart';
import '../../services/user_service.dart';
import '../../services/product_service.dart';

import '../../models/product.dart';
import 'merchant_edit_katalog_page.dart';

class MerchantDashboardPage extends StatefulWidget {
  const MerchantDashboardPage({super.key});

  @override
  State<MerchantDashboardPage> createState() => _MerchantDashboardPageState();
}

class _MerchantDashboardPageState extends State<MerchantDashboardPage> {
  final UserService _userService = UserService();
  final ProductService _productService = ProductService();

  // Merchant info
  String _namaBisnis = '';
  String? _profilePicture;

  // Products
  List<ProductModel> _products = [];
  bool _isLoading = true;
  bool _isTokoActive = true;

  // Warna tema
  static const Color tealDark = Color(0xFF0D3B2E);
  static const Color tealMid = Color(0xFF145C54);
  static const Color tealGradientEnd = Color(0xFF1A8A7A);
  static const Color toggleActive = Color(0xFF2AAA8A);
  static const Color saldoCardColor = Color(0xFF17584F);
  static const Color promoCardColor = Color(0xFF1E6E5E);
  static const Color limeGreen = Color(0xFFAEEA00);

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

        final allProducts =
            data.map((json) => ProductModel.fromJson(json)).toList();

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
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: tealMid))
          : RefreshIndicator(
              color: tealMid,
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header Area dengan gradient ──
                    _buildHeaderSection(),

                    // ── Status Operasional Toko ──
                    _buildStatusOperasionalSection(),

                    // ── Promo Kilat ──
                    _buildPromoKilatSection(),

                    // ── Katalog Saya ──
                    _buildKatalogSection(),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
    );
  }

  // ═══════════════════════════════════════════
  // HEADER SECTION (Gradient + Saldo Card)
  // ═══════════════════════════════════════════
  Widget _buildHeaderSection() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [tealDark, tealGradientEnd],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top bar: Merchant info + notification
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  // Merchant avatar
                  Container(
                    width: 48,
                    height: 48,
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
                              width: 48,
                              height: 48,
                              errorBuilder: (c, e, s) => const Icon(
                                Icons.storefront_rounded,
                                color: Colors.white70,
                                size: 24,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.storefront_rounded,
                            color: Colors.white70,
                            size: 24,
                          ),
                  ),
                  const SizedBox(width: 12),
                  // Nama & deskripsi
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _namaBisnis.isEmpty
                              ? 'Nama Merchant'
                              : _namaBisnis,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Mari kelola dan pantau usahamu\nmulai hari ini.',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withValues(alpha: 0.8),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Notification icon
                  Stack(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: const Icon(
                          Icons.notifications_outlined,
                          color: tealDark,
                          size: 24,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B), // Orange badge
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: tealDark,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '2',
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Saldo Card
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: _buildSaldoCard(),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // SALDO CARD
  // ═══════════════════════════════════════════
  Widget _buildSaldoCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: saldoCardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Top: Saldo row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB800),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Saldo',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      'Rp 0',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.visibility_outlined,
                      color: Colors.white.withValues(alpha: 0.7),
                      size: 18,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Divider
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          // Bottom: Transaksi & Penjualan
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                // Transaksi hari ini
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Transaksi hari ini',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              '0',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2AAA8A)
                                    .withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.trending_up,
                                    color: Color(0xFF4ADE80),
                                    size: 12,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '0%',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF4ADE80),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Divider vertikal
                Container(
                  width: 1,
                  height: 36,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
                // Penjualan kotor hari ini
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Penjualan kotor hari ini',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              'Rp 0',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.visibility_outlined,
                              color: Colors.white.withValues(alpha: 0.5),
                              size: 14,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // STATUS OPERASIONAL TOKO
  // ═══════════════════════════════════════════
  Widget _buildStatusOperasionalSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status Operasional Toko',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isTokoActive
                  ? limeGreen
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: _isTokoActive
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
              border: Border.all(
                color: _isTokoActive
                    ? limeGreen
                    : Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Ikon toko
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _isTokoActive
                        ? tealDark
                        : Colors.blueGrey[600],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                // Info text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Buka Toko',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _isTokoActive
                              ? tealDark
                              : const Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isTokoActive ? 'Aktif' : 'Tidak Aktif',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: _isTokoActive
                              ? tealDark
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Toggle
                Transform.scale(
                  scale: 1.1,
                  child: Switch(
                    value: _isTokoActive,
                    onChanged: (value) {
                      setState(() => _isTokoActive = value);
                    },
                    activeThumbColor: tealDark,
                    activeTrackColor: Colors.white,
                    inactiveThumbColor: Colors.grey[400],
                    inactiveTrackColor: Colors.grey[300],
                    trackOutlineColor:
                        WidgetStateProperty.all(Colors.transparent),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // PROMO KILAT
  // ═══════════════════════════════════════════
  Widget _buildPromoKilatSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [tealDark, promoCardColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: tealDark.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Promo Kilat',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Buat Promo Kilat, tarik pelanggan baru dan ramaikan usahamu.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.8),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            // Button
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Navigate to buat promo
                  },
                  icon: const Icon(
                    Icons.bolt_rounded,
                    size: 20,
                  ),
                  label: Text(
                    'Buat Promo',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: tealDark,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // KATALOG SAYA
  // ═══════════════════════════════════════════
  Widget _buildKatalogSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
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
                child: Text(
                  'Lihat Semua',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[500],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Product List
          _products.isEmpty
              ? _buildEmptyKatalog()
              : ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: _products.length > 5 ? 5 : _products.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _buildProductCard(_products[index]);
                  },
                ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // EMPTY KATALOG STATE
  // ═══════════════════════════════════════════
  Widget _buildEmptyKatalog() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
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
                Icons.shopping_bag_outlined,
                size: 36,
                color: Colors.grey[300],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada produk',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tambahkan produk melalui halaman Usaha',
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
  // PRODUCT CARD
  // ═══════════════════════════════════════════
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
              width: 120,
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
                          size: 32,
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.fastfood_rounded,
                        color: Colors.grey[400],
                        size: 32,
                      ),
                    ),
            ),
          ),
          // Detail Produk
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                              ? limeGreen
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          product.isAvailable ? 'Tersedia' : 'Kosong',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: product.isAvailable
                                ? tealDark
                                : Colors.grey[600],
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