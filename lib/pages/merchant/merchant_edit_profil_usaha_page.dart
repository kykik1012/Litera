import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/merchant.dart';
import '../../services/merchant_service.dart';
import '../../services/product_service.dart';
import '../../services/review_service.dart';
import '../../services/user_service.dart';
import '../../helpers/shared_pref_helper.dart';

class MerchantEditProfilUsahaPage extends StatefulWidget {
  const MerchantEditProfilUsahaPage({super.key});

  @override
  State<MerchantEditProfilUsahaPage> createState() => _MerchantEditProfilUsahaPageState();
}

class _MerchantEditProfilUsahaPageState extends State<MerchantEditProfilUsahaPage> {
  final MerchantService _merchantService = MerchantService();
  final ProductService _productService = ProductService();
  final ReviewService _reviewService = ReviewService();
  
  bool _isLoading = true;
  MerchantModel? _merchant;
  
  double _rating = 0.0;
  int _ulasanCount = 0;
  int _produkCount = 0;
  bool _isSaving = false;

  final UserService _userService = UserService();
  final ImagePicker _picker = ImagePicker();
  
  XFile? _bannerImage;
  Uint8List? _bannerBytes;
  XFile? _profileImage;
  File? _profileFile;

  // Controllers
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _bukaController = TextEditingController();
  final TextEditingController _tutupController = TextEditingController();
  final TextEditingController _tanggalController = TextEditingController();
  final TextEditingController _bulanController = TextEditingController();
  final TextEditingController _tahunController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();

  final List<String> _hariList = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu', 'Selalu'];
  final List<String> _selectedHari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];

  static const Color tealDark = Color(0xFF0D3B2E);
  static const Color limeGreen = Color(0xFFAEEA00);
  static const Color scaffoldBg = Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
    _loadMerchantData();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _bukaController.dispose();
    _tutupController.dispose();
    _tanggalController.dispose();
    _bulanController.dispose();
    _tahunController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  Future<void> _loadMerchantData() async {
    setState(() => _isLoading = true);
    try {
      final userId = await SharedPrefHelper.getUserId();
      if (userId != null) {
        final res = await _merchantService.getAllMerchants();
        if (res['success'] == true) {
          final List data = res['data'];
          final myMerchant = data.where((m) => m['user_id'].toString() == userId.toString()).toList();
          if (myMerchant.isNotEmpty) {
            _merchant = MerchantModel.fromJson(myMerchant.first);
            _populateFields();
            await _loadStats();
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading merchant data: $e");
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadStats() async {
    if (_merchant == null) return;
    try {
      // Products
      final prodRes = await _productService.getAllProducts();
      if (prodRes['success'] == true) {
        final List data = prodRes['data'];
        int count = 0;
        for (var p in data) {
          if (p['nama_bisnis']?.toString().toLowerCase() == _merchant!.namaBisnis.toLowerCase()) {
            count++;
          }
        }
        _produkCount = count;
      }
      
      // Reviews
      final revRes = await _reviewService.getAllReviews();
      if (revRes['success'] == true) {
        final List data = revRes['data'];
        int count = 0;
        double totalRating = 0;
        for (var r in data) {
          if (r['nama_bisnis']?.toString().toLowerCase() == _merchant!.namaBisnis.toLowerCase() && r['is_delete'] != true) {
            count++;
            totalRating += (r['rating'] as num).toDouble();
          }
        }
        _ulasanCount = count;
        _rating = count > 0 ? (totalRating / count) : 0.0;
      }
    } catch (e) {
      debugPrint("Error loading stats: $e");
    }
  }

  void _populateFields() {
    if (_merchant == null) return;
    
    _namaController.text = _merchant!.namaBisnis;
    
    // Parse time
    if (_merchant!.jamBuka != null) {
      _bukaController.text = _formatTime(_merchant!.jamBuka!);
    } else {
      _bukaController.text = "09:00";
    }
    
    if (_merchant!.jamTutup != null) {
      _tutupController.text = _formatTime(_merchant!.jamTutup!);
    } else {
      _tutupController.text = "21:00";
    }
    
    // Parse date
    if (_merchant!.usahaDidirikan != null) {
      try {
        final date = DateTime.parse(_merchant!.usahaDidirikan!);
        _tanggalController.text = date.day.toString().padLeft(2, '0');
        _bulanController.text = _getMonthName(date.month);
        _tahunController.text = date.year.toString();
      } catch (_) {}
    } else {
      _tanggalController.text = "17";
      _bulanController.text = "Oktober";
      _tahunController.text = "1976";
    }
    
    _deskripsiController.text = _merchant!.deskripsi ?? 'Kami menjual kue lapis rumahan dengan rasa manis legit dan tekstur lembut berlapis...';
  }

  String _formatTime(String timeStr) {
    if (timeStr.length >= 5) {
      return timeStr.substring(0, 5);
    }
    return timeStr;
  }

  String _getMonthName(int month) {
    const months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    if (month >= 1 && month <= 12) return months[month - 1];
    return month.toString();
  }

  int _getMonthNumber(String monthName) {
    const months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    final idx = months.indexOf(monthName);
    return idx != -1 ? idx + 1 : 1;
  }

  Future<void> _pickBanner() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _bannerImage = picked;
          _bannerBytes = bytes;
        });
      }
    } catch (e) {
      debugPrint("Error picking banner: $e");
    }
  }

  Future<void> _pickProfilePic() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (picked != null) {
        setState(() {
          _profileImage = picked;
          _profileFile = File(picked.path);
        });
      }
    } catch (e) {
      debugPrint("Error picking profile: $e");
    }
  }

  Future<void> _savePerubahan() async {
    if (_merchant == null) return;
    setState(() => _isSaving = true);
    try {
       final day = _tanggalController.text.padLeft(2, '0');
       final month = _getMonthNumber(_bulanController.text).toString().padLeft(2, '0');
       final year = _tahunController.text;
       final dateStr = "$year-$month-$day";

       final res = await _merchantService.updateMerchantInformation(
          id: int.parse(_merchant!.id),
          namaBisnis: _namaController.text,
          usahaDidirikan: dateStr,
          jamBuka: _bukaController.text,
          jamTutup: _tutupController.text,
          deskripsi: _deskripsiController.text,
          imageBytes: _bannerBytes,
          imageFileName: _bannerImage?.name,
       );

       if (_profileFile != null) {
          final userId = await SharedPrefHelper.getUserId();
          if (userId != null) {
             await _userService.uploadProfilePicture(id: userId, image: _profileFile!);
          }
       }

       if (!mounted) return;
       if (res['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil berhasil diperbarui')));
          Navigator.pop(context, true);
       } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Gagal memperbarui')));
       }
    } catch (e) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
       if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profil Usaha',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: tealDark))
        : SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderSection(),
                  const SizedBox(height: 24),
                  _buildJadwalOperasional(),
                  const SizedBox(height: 24),
                  _buildUsahaDimulaiSejak(),
                  const SizedBox(height: 24),
                  _buildKisahUsaha(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner & Profile Picture Stack
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Banner
              GestureDetector(
                onTap: _pickBanner,
                child: Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.brown[300],
                    image: _bannerBytes != null
                        ? DecorationImage(image: MemoryImage(_bannerBytes!), fit: BoxFit.cover)
                        : _merchant?.imageUrl != null
                            ? DecorationImage(image: NetworkImage(_merchant!.imageUrl!), fit: BoxFit.cover)
                            : const DecorationImage(image: AssetImage('assets/images/data_kosong.png'), fit: BoxFit.cover),
                  ),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 16,
                        child: const Icon(Icons.edit_outlined, size: 18, color: Colors.black),
                      ),
                    ),
                  ),
                ),
              ),
              // Profile Picture
              Positioned(
                bottom: -30,
                left: 16,
                child: GestureDetector(
                  onTap: _pickProfilePic,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: const Color(0xFFC8E6C9),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: _profileFile != null
                        ? ClipOval(child: Image.file(_profileFile!, fit: BoxFit.cover))
                        : _merchant?.profilePicture != null
                            ? ClipOval(child: Image.network(_merchant!.profilePicture!, fit: BoxFit.cover))
                            : const Icon(Icons.storefront, color: tealDark, size: 36),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          
          // Name and Address
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  controller: _namaController,
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: 'Nama Usaha',
                    hintStyle: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.edit_outlined, size: 20, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Jl. Sudirman Kp. Using, Jemberlor, Kec. Patrang, Kabupaten Jember', // Mock address for now
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700]),
          ),
          const SizedBox(height: 12),
          
          // Badges
          Row(
            children: [
              _buildBadge('Kuliner'),
              const SizedBox(width: 8),
              _buildBadge('Usaha Legendaris'),
            ],
          ),
          const SizedBox(height: 16),
          
          // Stats Card
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: tealDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(_rating > 0 ? _rating.toStringAsFixed(1) : '-', 'Rating'),
                _buildStatItem(_ulasanCount.toString(), 'Ulasan'),
                _buildStatItem(_produkCount.toString(), 'Produk'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Preview Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: limeGreen,
                foregroundColor: tealDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              child: Text(
                'Preview Profil',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: limeGreen,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: tealDark),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  Widget _buildJadwalOperasional() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Jadwal Operasional', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hari', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _hariList.map((hari) {
                  final isSelected = _selectedHari.contains(hari);
                  return ChoiceChip(
                    label: Text(hari, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: tealDark)),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() {
                        if (val) _selectedHari.add(hari);
                        else _selectedHari.remove(hari);
                      });
                    },
                    selectedColor: limeGreen,
                    backgroundColor: Colors.grey[100],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    side: BorderSide.none,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Buka', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        _buildTimeField(_bukaController),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tutup', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        _buildTimeField(_tutupController),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildTimeField(TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildUsahaDimulaiSejak() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Usaha Dimulai Sejak', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: _buildDateField('Tanggal', _tanggalController),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _buildDateField('Bulan', _bulanController),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: _buildDateField('Tahun', _tahunController),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: controller,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKisahUsaha() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kisah Usaha', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: TextField(
            controller: _deskripsiController,
            maxLines: 5,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[800]),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _savePerubahan,
            style: ElevatedButton.styleFrom(
              backgroundColor: limeGreen,
              foregroundColor: tealDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
            ),
            child: _isSaving 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: tealDark, strokeWidth: 2))
              : Text(
                  'Simpan Perubahan',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
          ),
        ),
      ],
    );
  }
}
