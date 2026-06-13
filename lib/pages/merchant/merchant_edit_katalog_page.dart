import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../services/merchant_service.dart';
import '../../helpers/shared_pref_helper.dart';
import 'merchant_edit_produk_page.dart';

class MerchantEditKatalogPage extends StatefulWidget {
  const MerchantEditKatalogPage({super.key});

  @override
  State<MerchantEditKatalogPage> createState() => _MerchantEditKatalogPageState();
}

class _MerchantEditKatalogPageState extends State<MerchantEditKatalogPage> {
  final ProductService _productService = ProductService();
  final MerchantService _merchantService = MerchantService();

  bool _isLoading = true;
  String _namaBisnis = '';
  
  // Dua list berbeda untuk Tab Aktif dan Dihapus
  List<ProductModel> _activeProducts = [];
  List<ProductModel> _deletedProducts = [];

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

        if (_namaBisnis.isNotEmpty) {
          final myProducts = allProducts.where((p) => p.namaBisnis == _namaBisnis).toList();
          
          setState(() {
            // Pisahkan produk berdasarkan status is_active
            _activeProducts = myProducts.where((p) => p.isActive == true).toList();
            _deletedProducts = myProducts.where((p) => p.isActive == false).toList();
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading catalog for edit: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteProduct(ProductModel product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus Produk', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin memindahkan ${product.namaProduk} ke daftar dihapus?'),
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
      _showLoadingDialog();
      try {
        final res = await _productService.deleteProduct(product.id);
        if (!mounted) return;
        Navigator.pop(context); // Tutup loading

        if (res["success"] == true) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produk berhasil dihapus')));
          _loadData(); // Refresh list
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus: ${res["message"] ?? ""}')));
        }
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Terjadi kesalahan saat menghapus')));
      }
    }
  }

  // --- FUNGSI BARU: PULIHKAN PRODUK ---
  Future<void> _restoreProduct(ProductModel product) async {
    _showLoadingDialog();
    try {
      final res = await _productService.restoreProduct(product.id);
      if (!mounted) return;
      Navigator.pop(context); // Tutup loading

      if (res["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produk berhasil dipulihkan'), backgroundColor: Colors.green));
        _loadData(); // Refresh list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memulihkan: ${res["message"] ?? ""}'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Terjadi kesalahan saat memulihkan'), backgroundColor: Colors.red));
    }
  }

  Future<void> _toggleAvailability(ProductModel product) async {
    try {
      final newStatus = !product.isAvailable;
      final res = await _productService.updateProductAvailability(
        id: product.id,
        namaProduk: product.namaProduk,
        deskripsi: product.deskripsi,
        hargaProduk: product.hargaProduk.toInt(),
        categoryId: product.categoryId ?? 0,
        isAvailable: newStatus,
      );

      if (!mounted) return;
      if (res["success"] == true || res["status"] == "success") {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status produk diperbarui')));
        _loadData();
      } else {
        final msg = res["message"] ?? 'Gagal update status';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Terjadi kesalahan saat update status')));
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: tealDark)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Gunakan DefaultTabController untuk membuat Sub Navigasi (Tabs)
    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
            'Katalog Saya',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A2E)),
          ),
          bottom: const TabBar(
            labelColor: tealDark,
            unselectedLabelColor: Colors.grey,
            indicatorColor: tealDark,
            tabs: [
              Tab(text: "Aktif"),
              Tab(text: "Dihapus"),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: tealDark))
            : TabBarView(
                children: [
                  _buildProductList(_activeProducts, isDeleted: false),
                  _buildProductList(_deletedProducts, isDeleted: true),
                ],
              ),
      ),
    );
  }

  Widget _buildProductList(List<ProductModel> products, {required bool isDeleted}) {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: tealDark,
      child: products.isEmpty
          ? SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 80),
                  child: Column(
                    children: [
                      Icon(
                        isDeleted ? Icons.delete_outline : Icons.inventory_2_outlined, 
                        size: 80, 
                        color: Colors.grey[300]
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isDeleted ? 'Tidak ada produk yang dihapus.' : 'Belum ada produk aktif.',
                        style: GoogleFonts.poppins(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: products.length,
              itemBuilder: (context, index) {
                return _buildEditProductCard(products[index], isDeleted: isDeleted);
              },
            ),
    );
  }

  Widget _buildEditProductCard(ProductModel product, {required bool isDeleted}) {
    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final String formattedPrice = formatCurrency.format(product.hargaProduk);
    final bool isAvailable = product.isAvailable;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        // Jika dihapus, background sedikit lebih gelap
        color: isDeleted ? Colors.grey[100] : (isAvailable ? Colors.white : Colors.grey[50]),
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
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bagian Gambar
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
                            // Jika dihapus, gambar menjadi abu-abu/grayscale
                            color: isDeleted ? Colors.grey : null,
                            colorBlendMode: isDeleted ? BlendMode.saturation : null,
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
                          color: isDeleted ? Colors.grey[600] : const Color(0xFF1A1A2E),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.deskripsi,
                        style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]),
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
                              color: isDeleted ? Colors.grey[600] : const Color(0xFF1A1A2E),
                            ),
                          ),
                          
                          // Badge Status (Tersedia / Habis / Dihapus)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDeleted ? Colors.red[100] : (isAvailable ? limeGreen : Colors.grey[300]),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isDeleted ? 'DIHAPUS' : (isAvailable ? 'Tersedia' : 'Habis'),
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isDeleted ? Colors.red[800] : (isAvailable ? tealDark : Colors.grey[700]),
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
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Divider(color: Colors.grey.shade200, height: 1),
          ),
          
          // Bagian Tombol Aksi
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                const Spacer(),
                
                // JIKA DIHAPUS -> HANYA TAMPILKAN TOMBOL PULIHKAN
                if (isDeleted)
                  SizedBox(
                    height: 32,
                    child: ElevatedButton.icon(
                      onPressed: () => _restoreProduct(product),
                      icon: const Icon(Icons.restore, size: 16),
                      label: Text('Pulihkan', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tealDark,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  )
                  
                // JIKA AKTIF -> TAMPILKAN EDIT, HABIS/TERSEDIA, HAPUS
                else ...[
                  SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => MerchantEditProdukPage(product: product)),
                        );
                        if (result == true) _loadData();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: limeGreen,
                        foregroundColor: tealDark,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('Edit', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 8),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}