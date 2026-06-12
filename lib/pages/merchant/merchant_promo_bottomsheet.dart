import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/product.dart';
import '../../services/promotion_service.dart';

class MerchantPromoBottomSheet extends StatefulWidget {
  final List<ProductModel> products;

  const MerchantPromoBottomSheet({super.key, required this.products});

  @override
  State<MerchantPromoBottomSheet> createState() =>
      _MerchantPromoBottomSheetState();
}

class _MerchantPromoBottomSheetState extends State<MerchantPromoBottomSheet> {
  final PromotionService _promoService = PromotionService();

  static const Color primaryGreen = Color(0xFF003D33);
  static const Color accentGreen = Color(0xFFAEEA00);

  ProductModel? _selectedProduct;
  int _diskon = 20;
  int _kuota = 10;
  int? _durasiMenit = 60;
  final TextEditingController _kuotaController =
      TextEditingController(text: '10');
  final TextEditingController _customDurasiController =
      TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.products.isNotEmpty) {
      _selectedProduct = widget.products.first;
    }
  }

  @override
  void dispose() {
    _kuotaController.dispose();
    _customDurasiController.dispose();
    super.dispose();
  }

  String _formatCurrency(num price) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(price);
  }

  Future<void> _submitPromo() async {
    if (_selectedProduct == null) {
      _showSnackbar('Pilih produk terlebih dahulu', isError: true);
      return;
    }

    final durasi =
        _durasiMenit ?? int.tryParse(_customDurasiController.text);
    if (durasi == null || durasi <= 0) {
      _showSnackbar('Masukkan durasi yang valid', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final now = DateTime.now();
    final expired = now.add(Duration(minutes: durasi));
    final fmt = DateFormat("yyyy-MM-dd'T'HH:mm:ss");

    final result = await _promoService.createPromotion(
      productId: int.parse(_selectedProduct!.id.toString()),
      tipePromo: 'FLASH_SALE',
      diskon: _diskon,
      kuota: _kuota,
      tanggalBerlaku: fmt.format(now),
      tanggalExpired: fmt.format(expired),
    );

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      _showSnackbar('Promo berhasil dibuat!');
      if (mounted) Navigator.pop(context, true);
    } else {
      _showSnackbar(
        result['message'] ?? 'Gagal membuat promo',
        isError: true,
      );
    }
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : primaryGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, size: 22),
                ),
                Text(
                  'Promo Kilat',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 22),
              ],
            ),
            const SizedBox(height: 20),

            // ── Pilih Produk (dropdown jika lebih dari 1) ──
            if (widget.products.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'Belum ada produk. Tambahkan produk terlebih dahulu.',
                    style: GoogleFonts.poppins(
                        color: Colors.grey, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else ...[
              if (widget.products.length > 1) ...[
                Text('Pilih Produk',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                DropdownButtonFormField<ProductModel>(
                  value: _selectedProduct,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  items: widget.products
                      .map((p) => DropdownMenuItem(
                            value: p,
                            child: Text(p.namaProduk,
                                style:
                                    GoogleFonts.poppins(fontSize: 13)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedProduct = v),
                ),
                const SizedBox(height: 16),
              ],

              // ── Produk Terpilih ──
              if (_selectedProduct != null) _buildSelectedProduct(),
              const SizedBox(height: 20),

              // ── Diskon Slider ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Diskon',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  Text('$_diskon%',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: primaryGreen)),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: accentGreen,
                  thumbColor: primaryGreen,
                  inactiveTrackColor: Colors.grey[200],
                  overlayColor: primaryGreen.withOpacity(0.1),
                ),
                child: Slider(
                  value: _diskon.toDouble(),
                  min: 5,
                  max: 100,
                  divisions: 19,
                  onChanged: (v) => setState(() => _diskon = v.toInt()),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('5%',
                      style: GoogleFonts.poppins(
                          color: Colors.grey, fontSize: 11)),
                  Text('100%',
                      style: GoogleFonts.poppins(
                          color: Colors.grey, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 20),

              // ── Kuota ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Jumlah Promo',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  Text('$_kuota',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: primaryGreen)),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _kuotaController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: primaryGreen),
                  ),
                ),
                onChanged: (v) {
                  final val = int.tryParse(v);
                  if (val != null) setState(() => _kuota = val);
                },
              ),
              const SizedBox(height: 20),

              // ── Durasi ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Durasi',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(
                    _durasiMenit != null
                        ? '$_durasiMenit menit'
                        : '${_customDurasiController.text.isEmpty ? '...' : _customDurasiController.text} menit',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: primaryGreen),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildDurasiChip(30),
                  const SizedBox(width: 8),
                  _buildDurasiChip(60),
                  const SizedBox(width: 8),
                  _buildDurasiChip(120),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _durasiMenit = null),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _durasiMenit == null
                              ? accentGreen
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: _durasiMenit == null
                            ? TextField(
                                controller: _customDurasiController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: primaryGreen),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: '...m',
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (_) => setState(() {}),
                              )
                            : Text(
                                '....m',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600]),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ── Tombol Submit ──
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitPromo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentGreen,
                    foregroundColor: primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Buat Promo',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedProduct() {
    final p = _selectedProduct!;
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 64,
            height: 64,
            child: p.imageUrl != null && p.imageUrl!.isNotEmpty
                ? Image.network(
                    p.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      color: Colors.grey[200],
                      child: Icon(Icons.fastfood_rounded,
                          color: Colors.grey[400], size: 28),
                    ),
                  )
                : Container(
                    color: Colors.grey[200],
                    child: Icon(Icons.fastfood_rounded,
                        color: Colors.grey[400], size: 28),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p.namaProduk,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                p.deskripsi,
                style: GoogleFonts.poppins(
                    color: Colors.grey, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                _formatCurrency(p.hargaProduk),
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDurasiChip(int menit) {
    final selected = _durasiMenit == menit;
    return GestureDetector(
      onTap: () => setState(() {
        _durasiMenit = menit;
        _customDurasiController.clear();
      }),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? accentGreen : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '${menit}m',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? primaryGreen : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}