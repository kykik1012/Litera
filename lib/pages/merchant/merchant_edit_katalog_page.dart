import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../services/merchant_service.dart';
import '../../helpers/shared_pref_helper.dart';

class MerchantEditKatalogPage extends StatefulWidget {
  const MerchantEditKatalogPage({super.key});

  @override
  State<MerchantEditKatalogPage> createState() => _MerchantEditKatalogPageState();
}

class _MerchantEditKatalogPageState extends State<MerchantEditKatalogPage> {
  final ProductService _productService = ProductService();
  final MerchantService _merchantService = MerchantService();

  bool _isLoading = true;
  List<ProductModel> _products = [];
  String _namaBisnis = '';

  static const Color tealDark = Color(0xFF145C54);
  static const Color limeGreen = Color(0xFFB8E926);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final userId = await SharedPrefHelper.getUserId() ?? 0;
      if (userId == 0) return;

      final merchantResponse = await _merchantService.getAllMerchants();
      if (merchantResponse["success"] == true && merchantResponse["data"] != null) {
        final List merchants = merchantResponse["data"];
        for (var m in merchants) {
          if (m["user_id"].toString() == userId.toString()) {
            _namaBisnis = m["nama_bisnis"] ?? 'Nama Merchant';
            break;
          }
        }
      }

      final productResponse = await _productService.getAllProducts();
      if (productResponse["success"] == true && productResponse["data"] != null) {
        final List data = productResponse["data"];
        final allProducts = data.map((json) => ProductModel.fromJson(json)).toList();

        // Filter by merchant name
        if (_namaBisnis.isNotEmpty) {
          _products = allProducts.where((p) => p.namaBisnis == _namaBisnis).toList();
        } else {
          _products = allProducts;
        }
      }
    } catch (e) {
      debugPrint("Error loading catalog for edit: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteProduct(ProductModel product) async {
    // Tampilkan konfirmasi
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus Produk', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin menghapus ${product.namaProduk}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Hapus', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Panggil API delete
      try {
        final res = await _productService.deleteProduct(product.id);
        if (!mounted) return;
        if (res["success"] == true) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produk berhasil dihapus')));
          _loadData(); // Refresh list
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus: ${res["message"] ?? ""}')));
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Terjadi kesalahan saat menghapus')));
      }
    }
  }

  Future<void> _toggleAvailability(ProductModel product) async {
    try {
      final newStatus = !product.isAvailable;
      final res = await _productService.updateProductAvailability(product.id, newStatus);
      if (!mounted) return;
      if (res["success"] == true || res["status"] == "success") {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status produk diperbarui')));
        _loadData();
      } else {
        // Mock fallback if API not ready
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('API update status mungkin belum tersedia')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Terjadi kesalahan saat update status')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1A1A2E), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Edit Katalog',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A2E),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: tealDark))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: tealDark,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Katalog Saya',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_products.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: Text(
                            'Belum ada produk.',
                            style: GoogleFonts.poppins(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ..._products.map((p) => _buildEditProductCard(p)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildEditProductCard(ProductModel product) {
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final String formattedPrice = formatCurrency.format(product.hargaProduk);
    
    // Warnanya sesuai desain foto (merah muda = habis, hijau lime = tersedia)
    final bool isAvailable = product.isAvailable;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Bagian atas: Gambar dan Info Produk
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gambar Produk
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[200],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                        ? Image.network(
                            product.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, st) => const Icon(Icons.fastfood, color: Colors.grey),
                          )
                        : const Icon(Icons.fastfood, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 12),
                // Info Produk
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.namaProduk,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A2E),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.deskripsi,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            formattedPrice,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1A2E),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isAvailable ? limeGreen : Colors.grey[300],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isAvailable ? 'Tersedia' : 'Kosong',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isAvailable ? tealDark : Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Divider (optional, di foto terlihat seperti box button)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Divider(color: Colors.grey.shade100, height: 1),
          ),
          
          // Bagian bawah: Tombol Aksi
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Tombol Edit
                SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Navigate to Edit Product Form
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fitur edit detail produk segera hadir')));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: limeGreen,
                      foregroundColor: tealDark,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      'Edit',
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Tombol Habis / Tersedia
                SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    onPressed: () => _toggleAvailability(product),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAvailable ? const Color(0xFFFFE5E5) : limeGreen,
                      foregroundColor: isAvailable ? Colors.red : tealDark,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      isAvailable ? 'Habis' : 'Tersedia',
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Tombol Delete
                SizedBox(
                  height: 32,
                  width: 40,
                  child: ElevatedButton(
                    onPressed: () => _deleteProduct(product),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFE5E5),
                      foregroundColor: Colors.red,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Icon(Icons.delete_outline, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
