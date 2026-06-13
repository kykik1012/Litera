import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/product.dart';
import '../../services/product_service.dart';

class MerchantEditProdukPage extends StatefulWidget {
  final ProductModel product;

  const MerchantEditProdukPage({super.key, required this.product});

  @override
  State<MerchantEditProdukPage> createState() =>
      _MerchantEditProdukPageState();
}

class _MerchantEditProdukPageState extends State<MerchantEditProdukPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _namaController;
  late TextEditingController _deskripsiController;
  late TextEditingController _hargaController;

  // Kategori dari API
  List<Map<String, dynamic>> _kategoriList = [];
  int? _selectedCategoryId;
  bool _isCategoriesLoading = true;

  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  bool _isLoading = false;

  final ProductService _productService = ProductService();
  final ImagePicker _picker = ImagePicker();

  // Warna tema
  static const Color tealDark = Color(0xFF145C54);
  static const Color limeGreen = Color(0xFFB8E926);

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.product.namaProduk);
    _deskripsiController = TextEditingController(text: widget.product.deskripsi);
    _hargaController = TextEditingController(text: widget.product.hargaProduk.toStringAsFixed(0));
    _selectedCategoryId = widget.product.categoryId;
    
    _loadInitialData();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _deskripsiController.dispose();
    _hargaController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await _loadCategories();
  }

  // Memuat kategori dari API
  Future<void> _loadCategories() async {
    try {
      final response = await _productService.getCategories();
      if (response["success"] == true && response["data"] != null) {
        final List data = response["data"];
        if (!mounted) return;
        setState(() {
          _kategoriList = data.map((item) => {
            'id': int.tryParse(item['id'].toString()) ?? 0,
            'category_name': item['category_name'] as String,
          }).toList();
          
          // Jika selectedCategory tidak ada di daftar kategori, set null
          if (_selectedCategoryId != null) {
            bool found = _kategoriList.any((cat) => cat['id'] == _selectedCategoryId);
            if (!found) _selectedCategoryId = null;
          }
          
          _isCategoriesLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() => _isCategoriesLoading = false);
      }
    } catch (e) {
      debugPrint("Error loading categories: $e");
      if (mounted) {
        setState(() => _isCategoriesLoading = false);
      }
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pilih Sumber Gambar',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: tealDark.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: tealDark),
                ),
                title: Text(
                  'Kamera',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _getImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: tealDark.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_rounded,
                      color: tealDark),
                ),
                title: Text(
                  'Galeri',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _getImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImage = pickedFile;
          _selectedImageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih gambar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _simpanProduk() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pilih kategori terlebih dahulu',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _productService.updateProduct(
        id: widget.product.id,
        namaProduk: _namaController.text.trim(),
        deskripsi: _deskripsiController.text.trim(),
        hargaProduk: int.parse(_hargaController.text.trim()),
        categoryId: _selectedCategoryId!,
        isAvailable: widget.product.isAvailable,
        imageBytes: _selectedImageBytes,
        imageFileName: _selectedImage?.name,
      );

      if (!mounted) return;

      if (response["success"] == true || response["status"] == "success") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Produk berhasil diupdate!',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: tealDark,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      } else {
        final message = response["message"] ?? "Gagal mengupdate produk";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message, style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A2E)),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Edit Produk',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A2E),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Upload Gambar ──
              _buildImagePicker(),
              const SizedBox(height: 24),

              // ── Nama Produk ──
              _buildLabel('Nama Produk'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _namaController,
                hintText: 'Nama produk',
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Nama produk wajib diisi' : null,
              ),
              const SizedBox(height: 20),

              // ── Deskripsi ──
              _buildLabel('Deskripsi'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _deskripsiController,
                hintText: 'Isi deskripsi produk',
                maxLines: 3,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Deskripsi wajib diisi' : null,
              ),
              const SizedBox(height: 20),

              // ── Kategori ──
              _buildLabel('Kategori'),
              const SizedBox(height: 8),
              _buildDropdown(),
              const SizedBox(height: 20),

              // ── Harga ──
              _buildLabel('Harga'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _hargaController,
                hintText: '0',
                keyboardType: TextInputType.number,
                prefixText: 'Rp ',
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Harga wajib diisi';
                  if (int.tryParse(v.trim()) == null) return 'Harga harus berupa angka';
                  return null;
                },
              ),
              const SizedBox(height: 40),

              // ── Tombol Simpan ──
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _simpanProduk,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: limeGreen,
                    foregroundColor: tealDark,
                    disabledBackgroundColor: limeGreen.withValues(alpha: 0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: tealDark,
                          ),
                        )
                      : Text(
                          'Simpan Perubahan',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    ImageProvider? currentImage;
    if (_selectedImageBytes != null) {
      currentImage = MemoryImage(_selectedImageBytes!);
    } else if (widget.product.imageUrl != null && widget.product.imageUrl!.isNotEmpty) {
      currentImage = NetworkImage(widget.product.imageUrl!);
    }

    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
          image: currentImage != null
              ? DecorationImage(
                  image: currentImage,
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: currentImage == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fastfood_rounded,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap untuk pilih gambar',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              )
            : Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1A1A2E),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? prefixText,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.poppins(
        fontSize: 14,
        color: const Color(0xFF1A1A2E),
      ),
      decoration: InputDecoration(
        hintText: hintText,
        prefixText: prefixText,
        hintStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.grey[400],
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: tealDark, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    if (_isCategoriesLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Memuat kategori...',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<int>(
      value: _selectedCategoryId,
      hint: Text(
        'Pilih Kategori',
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.grey[400],
        ),
      ),
      style: GoogleFonts.poppins(
        fontSize: 14,
        color: const Color(0xFF1A1A2E),
      ),
      icon: Icon(Icons.unfold_more, color: Colors.grey[400]),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: tealDark, width: 1.5),
        ),
      ),
      items: _kategoriList.map((kategori) {
        return DropdownMenuItem<int>(
          value: kategori['id'] as int,
          child: Text(kategori['category_name'] as String),
        );
      }).toList(),
      onChanged: (val) {
        setState(() => _selectedCategoryId = val);
      },
    );
  }
}
