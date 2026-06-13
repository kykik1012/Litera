import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../helpers/shared_pref_helper.dart';
import '../../services/user_service.dart';
import '../../services/merchant_service.dart';
import '../../services/product_service.dart';
import '../../services/promotion_service.dart';
import '../../models/product.dart';
import '../../models/promotion.dart';

class MerchantTambahPromoPage extends StatefulWidget {
  // Jika parameter ini terisi, berarti halaman berjalan dalam Mode Edit
  final PromotionModel? existingPromo;

  const MerchantTambahPromoPage({super.key, this.existingPromo});

  @override
  State<MerchantTambahPromoPage> createState() => _MerchantTambahPromoPageState();
}

class _MerchantTambahPromoPageState extends State<MerchantTambahPromoPage> {
  final UserService _userService = UserService();
  final MerchantService _merchantService = MerchantService();
  final ProductService _productService = ProductService();
  final PromotionService _promotionService = PromotionService();

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _diskonController = TextEditingController();
  final TextEditingController _kuotaController = TextEditingController();

  List<ProductModel> _myProducts = [];
  bool _isLoadingProducts = true;
  bool _isSubmitting = false;

  String? _selectedProductId;
  String _selectedTipePromo = 'FLASH_SALE';
  DateTime? _tanggalBerlaku;
  DateTime? _tanggalExpired;

  final List<String> _tipePromoList = ['FLASH_SALE', 'DISCOUNT_REGULAR', 'SPESIAL_HARI_RAYA', 'CUCI_GUDANG'];

  static const Color tealDark = Color(0xFF0D3B2E);
  static const Color limeGreen = Color(0xFFAEEA00);

  // Mengecek apakah kita dalam mode edit
  bool get _isEditMode => widget.existingPromo != null; 

  @override
  void initState() {
    super.initState();
    
    // Jika mode edit, isi form dengan data promo yang lama
    if (_isEditMode) {
      _selectedProductId = widget.existingPromo!.productId;
      _selectedTipePromo = widget.existingPromo!.tipePromo;
      _diskonController.text = widget.existingPromo!.diskon.toString();
      _kuotaController.text = widget.existingPromo!.kuota.toString();
      _tanggalBerlaku = widget.existingPromo!.tanggalBerlaku;
      _tanggalExpired = widget.existingPromo!.tanggalExpired;

      // Pastikan tipe promo yang didapat dari server ada di dalam daftar _tipePromoList
      if (!_tipePromoList.contains(_selectedTipePromo)) {
        _tipePromoList.add(_selectedTipePromo); 
      }
    }

    _loadMyProducts();
  }

  @override
  void dispose() {
    _diskonController.dispose();
    _kuotaController.dispose();
    super.dispose();
  }

  Future<void> _loadMyProducts() async {
    setState(() => _isLoadingProducts = true);
    try {
      final userId = await SharedPrefHelper.getUserId() ?? 0;
      if (userId == 0) return;

      String myMerchantName = '';

      final merchantRes = await _merchantService.getAllMerchants();
      if (merchantRes['success'] == true) {
        final List<dynamic> mList = merchantRes['data'];
        final myMerchant = mList.firstWhere(
          (m) => m['user_id'].toString() == userId.toString(),
          orElse: () => null,
        );
        if (myMerchant != null && myMerchant['nama_bisnis'] != null) {
          myMerchantName = myMerchant['nama_bisnis'].toString();
        } else {
          final userRes = await _userService.getUserById(userId);
          if (userRes['success'] == true) {
            myMerchantName = userRes['data']['name'] ?? '';
          }
        }
      }

      if (myMerchantName.isNotEmpty) {
        final prodRes = await _productService.getAllProducts();
        if (prodRes['success'] == true) {
          final List<dynamic> pList = prodRes['data'];
          setState(() {
            _myProducts = pList
                .map((json) => ProductModel.fromJson(json))
                .where((p) => p.namaBisnis.toLowerCase() == myMerchantName.toLowerCase())
                .toList();
            
            // Perbaiki issue jika Produk dari Promo Lama ternyata sudah dihapus dari katalog
            if (_isEditMode && !_myProducts.any((p) => p.id.toString() == _selectedProductId)) {
              _selectedProductId = null; // Reset pilihan
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Gagal memuat produk: $e");
    } finally {
      if (mounted) setState(() => _isLoadingProducts = false);
    }
  }

  Future<void> _pickDateTime(bool isStart) async {
    DateTime initialDate = DateTime.now();
    if (!isStart && _tanggalBerlaku != null) {
      initialDate = _tanggalBerlaku!.add(const Duration(hours: 1));
    }

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)), // Izinkan pilih hari ini
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: tealDark)),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      if (!mounted) return;
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: tealDark)),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        setState(() {
          final selectedDateTime = DateTime(
            pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute,
          );

          if (isStart) {
            _tanggalBerlaku = selectedDateTime;
            if (_tanggalExpired != null && _tanggalExpired!.isBefore(_tanggalBerlaku!)) {
              _tanggalExpired = null;
            }
          } else {
            _tanggalExpired = selectedDateTime;
          }
        });
      }
    }
  }

  Future<void> _submitPromo() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProductId == null) {
      _showError("Pilih produk terlebih dahulu!");
      return;
    }
    if (_tanggalBerlaku == null || _tanggalExpired == null) {
      _showError("Tentukan Tanggal Berlaku & Expired!");
      return;
    }
    if (_tanggalExpired!.isBefore(_tanggalBerlaku!)) {
      _showError("Tanggal Expired tidak boleh lebih awal dari Tanggal Berlaku!");
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final String tglBerlakuIso = _tanggalBerlaku!.toUtc().toIso8601String();
      final String tglExpiredIso = _tanggalExpired!.toUtc().toIso8601String();

      Map<String, dynamic> response;

      // --- PERCABANGAN LOGIKA SIMPAN / EDIT ---
      if (_isEditMode) {
        response = await _promotionService.updatePromotion(
          promotionId: widget.existingPromo!.id,
          productId: int.parse(_selectedProductId!),
          tipePromo: _selectedTipePromo,
          diskon: int.parse(_diskonController.text),
          kuota: int.parse(_kuotaController.text),
          tanggalBerlaku: tglBerlakuIso,
          tanggalExpired: tglExpiredIso,
        );
      } else {
        response = await _promotionService.createPromotion(
          productId: int.parse(_selectedProductId!),
          tipePromo: _selectedTipePromo,
          diskon: int.parse(_diskonController.text),
          kuota: int.parse(_kuotaController.text),
          tanggalBerlaku: tglBerlakuIso,
          tanggalExpired: tglExpiredIso,
        );
      }

      if (response['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode ? "Promo berhasil diperbarui!" : "Promo berhasil dibuat!"), 
            backgroundColor: Colors.green
          ),
        );
        Navigator.pop(context, true);
      } else {
        _showError(response['message'] ?? "Gagal menyimpan promo");
      }
    } catch (e) {
      _showError("Terjadi kesalahan jaringan: $e");
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 16),
      child: Text(text, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: tealDark)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: tealDark,
        foregroundColor: Colors.white,
        title: Text(
          _isEditMode ? "Edit Promo" : "Buat Promo Baru",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        elevation: 0,
      ),
      body: _isLoadingProducts
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    _isEditMode ? "Edit Detail Promo" : "Detail Promo Baru",
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  Text(
                    _isEditMode ? "Perbarui informasi di bawah ini." : "Isi form di bawah ini untuk mengaktifkan diskon.",
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 10),

                  // 1. DROPDOWN PRODUK
                  _buildLabel("Pilih Produk"),
                  DropdownButtonFormField<String>(
                    value: _selectedProductId,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    hint: const Text("Pilih produk untuk didiskon"),
                    items: _myProducts.map((ProductModel product) {
                      return DropdownMenuItem<String>(
                        value: product.id.toString(),
                        child: Text(product.namaProduk, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedProductId = value),
                    validator: (value) => value == null ? "Produk wajib dipilih" : null,
                  ),

                  // 2. TIPE PROMO
                  _buildLabel("Tipe Promo"),
                  DropdownButtonFormField<String>(
                    value: _selectedTipePromo,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: _tipePromoList.map((String type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type.replaceAll('_', ' ')),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedTipePromo = value!),
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel("Diskon (%)"),
                            TextFormField(
                              controller: _diskonController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: "Misal: 20",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                suffixText: "%",
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return "Wajib isi";
                                if (int.tryParse(value) == null) return "Angka!";
                                if (int.parse(value) > 100 || int.parse(value) < 1) return "1 - 100";
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel("Kuota Promo"),
                            TextFormField(
                              controller: _kuotaController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: "Misal: 50",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                suffixIcon: const Icon(Icons.people_outline),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return "Wajib isi";
                                if (int.tryParse(value) == null) return "Angka!";
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  _buildLabel("Tanggal & Waktu Mulai"),
                  InkWell(
                    onTap: () => _pickDateTime(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _tanggalBerlaku != null 
                                ? DateFormat('dd MMM yyyy, HH:mm').format(_tanggalBerlaku!) 
                                : "Pilih waktu mulai",
                            style: TextStyle(color: _tanggalBerlaku != null ? Colors.black : Colors.grey[600]),
                          ),
                          const Icon(Icons.calendar_month, color: tealDark),
                        ],
                      ),
                    ),
                  ),

                  _buildLabel("Tanggal & Waktu Berakhir"),
                  InkWell(
                    onTap: () => _pickDateTime(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _tanggalExpired != null 
                                ? DateFormat('dd MMM yyyy, HH:mm').format(_tanggalExpired!) 
                                : "Pilih waktu berakhir",
                            style: TextStyle(color: _tanggalExpired != null ? Colors.black : Colors.grey[600]),
                          ),
                          const Icon(Icons.calendar_month, color: Colors.red),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitPromo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: limeGreen,
                        foregroundColor: tealDark,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: tealDark)
                          : Text(
                              _isEditMode ? "Perbarui Promo" : "Simpan & Aktifkan Promo",
                              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}