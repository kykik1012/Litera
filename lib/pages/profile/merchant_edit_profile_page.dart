import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../helpers/shared_pref_helper.dart';
import '../../services/merchant_service.dart';

class MerchantEditProfilePage extends StatefulWidget {
  const MerchantEditProfilePage({super.key});

  @override
  State<MerchantEditProfilePage> createState() => _MerchantEditProfilePageState();
}

class _MerchantEditProfilePageState extends State<MerchantEditProfilePage> {
  final MerchantService _merchantService = MerchantService();

  bool isLoading = true;
  bool isSaving = false;

  String merchantId = "";
  
  // Variabel Gambar
  File? selectedImageProfile;
  File? selectedImageQr;
  String? existingProfileUrl;
  String? existingQrUrl;

  // Controllers untuk teks
  final namaBisnisController = TextEditingController();
  final deskripsiController = TextEditingController();

  // Variabel untuk Tanggal dan Waktu (Agar formatnya pasti benar)
  DateTime? selectedTanggalBerdiri;
  TimeOfDay? selectedJamBuka;
  TimeOfDay? selectedJamTutup;

  // Warna Tema Litera
  final Color darkText = const Color(0xFF1A1A2E);
  final Color subtitleColor = const Color(0xFF6B7280);
  final Color tealColor = const Color(0xFF1A7A6D);
  final Color limeGreen = const Color(0xFFB8E926);

  @override
  void initState() {
    super.initState();
    _loadMerchantData();
  }

  Future<void> _loadMerchantData() async {
    try {
      final userId = await SharedPrefHelper.getUserId() ?? 0;
      if (userId == 0) throw Exception("Sesi tidak valid");

      // Cari merchant_id milik user yang sedang login
      final res = await _merchantService.getAllMerchants();
      if (res['success'] == true) {
        final List<dynamic> merchants = res['data'];
        final myMerchant = merchants.firstWhere(
          (m) => m['user_id'].toString() == userId.toString(),
          orElse: () => null,
        );

        if (myMerchant != null) {
          merchantId = myMerchant['id'].toString();
          namaBisnisController.text = myMerchant['nama_bisnis'] ?? "";
          deskripsiController.text = myMerchant['deskripsi'] ?? "";
          
          existingProfileUrl = myMerchant['image_url'];
          existingQrUrl = myMerchant['image_qr'];

          // Parse Tanggal Berdiri
          if (myMerchant['usaha_didirikan'] != null) {
            selectedTanggalBerdiri = DateTime.tryParse(myMerchant['usaha_didirikan'].toString());
          }
          
          // Parse Jam
          if (myMerchant['jam_buka'] != null) {
            final parts = myMerchant['jam_buka'].toString().split(':');
            if (parts.length >= 2) selectedJamBuka = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
          }
          if (myMerchant['jam_tutup'] != null) {
            final parts = myMerchant['jam_tutup'].toString().split(':');
            if (parts.length >= 2) selectedJamTutup = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // --- FUNGSI PILIH GAMBAR ---
  Future<void> pickImage(bool isProfile) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image == null) return;
    setState(() {
      if (isProfile) {
        selectedImageProfile = File(image.path);
      } else {
        selectedImageQr = File(image.path);
      }
    });
  }

  // --- FUNGSI PILIH TANGGAL ---
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedTanggalBerdiri ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(colorScheme: ColorScheme.light(primary: tealColor)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => selectedTanggalBerdiri = picked);
  }

  // --- FUNGSI PILIH JAM ---
  Future<void> _pickTime(bool isBuka) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: (isBuka ? selectedJamBuka : selectedJamTutup) ?? const TimeOfDay(hour: 8, minute: 0),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(colorScheme: ColorScheme.light(primary: tealColor)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isBuka) selectedJamBuka = picked;
        else selectedJamTutup = picked;
      });
    }
  }

  // --- FUNGSI SIMPAN ---
  Future<void> saveProfile() async {
    if (namaBisnisController.text.isEmpty || selectedTanggalBerdiri == null || selectedJamBuka == null || selectedJamTutup == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mohon lengkapi semua data wajib")));
      return;
    }

    setState(() => isSaving = true);

    try {
      // Format tanggal dan jam ke string sesuai format Swagger
      String formattedDate = DateFormat('yyyy-MM-dd').format(selectedTanggalBerdiri!);
      String formatTime(TimeOfDay time) => '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';

      final response = await _merchantService.updateMerchantInformation(
        id: merchantId,
        namaBisnis: namaBisnisController.text,
        deskripsi: deskripsiController.text,
        usahaDidirikan: formattedDate,
        jamBuka: formatTime(selectedJamBuka!),
        jamTutup: formatTime(selectedJamTutup!),
        imageProfile: selectedImageProfile,
        imageQr: selectedImageQr,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response["message"] ?? "Berhasil disimpan")));

      if (response["success"] == true) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal menyimpan: $e")));
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(backgroundColor: Colors.white, body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.chevron_left_rounded, size: 28, color: darkText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Edit Profil Toko', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: darkText)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- UPLOAD FOTO PROFIL ---
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => pickImage(true),
                    child: Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle, color: Colors.grey[200],
                        border: Border.all(color: tealColor, width: 2),
                      ),
                      child: ClipOval(
                        child: selectedImageProfile != null
                            ? Image.file(selectedImageProfile!, fit: BoxFit.cover)
                            : existingProfileUrl != null
                                ? Image.network(existingProfileUrl!, fit: BoxFit.cover)
                                : Icon(Icons.storefront, size: 40, color: tealColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text("Ubah Foto Toko", style: GoogleFonts.poppins(fontSize: 13, color: tealColor, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // --- FORM NAMA BISNIS ---
            _buildLabeledField(label: 'Nama Bisnis *', controller: namaBisnisController, hintText: 'Masukkan nama bisnis'),
            const SizedBox(height: 20),

            // --- FORM DESKRIPSI ---
            _buildLabeledField(label: 'Deskripsi Toko', controller: deskripsiController, hintText: 'Jelaskan tentang tokomu', maxLines: 3),
            const SizedBox(height: 20),

            // --- PILIH TANGGAL BERDIRI ---
            Text('Tanggal Usaha Didirikan *', style: GoogleFonts.poppins(fontSize: 12, color: subtitleColor)),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(selectedTanggalBerdiri != null ? DateFormat('dd MMMM yyyy', 'id_ID').format(selectedTanggalBerdiri!) : "Pilih Tanggal",
                        style: GoogleFonts.poppins(fontSize: 14, color: selectedTanggalBerdiri != null ? darkText : Colors.grey)),
                    Icon(Icons.calendar_month, color: tealColor),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- PILIH JAM OPERASIONAL ---
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Jam Buka *', style: GoogleFonts.poppins(fontSize: 12, color: subtitleColor)),
                      GestureDetector(
                        onTap: () => _pickTime(true),
                        child: Container(
                          margin: const EdgeInsets.only(top: 8), padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(selectedJamBuka?.format(context) ?? "Buka", style: GoogleFonts.poppins(fontSize: 14)),
                              Icon(Icons.access_time, color: tealColor, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Jam Tutup *', style: GoogleFonts.poppins(fontSize: 12, color: subtitleColor)),
                      GestureDetector(
                        onTap: () => _pickTime(false),
                        child: Container(
                          margin: const EdgeInsets.only(top: 8), padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(selectedJamTutup?.format(context) ?? "Tutup", style: GoogleFonts.poppins(fontSize: 14)),
                              Icon(Icons.access_time, color: tealColor, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // --- UPLOAD QRIS ---
            Text('Upload QRIS Pembayaran', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: darkText)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => pickImage(false),
              child: Container(
                width: double.infinity, height: 160,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                ),
                child: selectedImageQr != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(selectedImageQr!, fit: BoxFit.contain))
                    : existingQrUrl != null && existingQrUrl!.isNotEmpty
                        ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(existingQrUrl!, fit: BoxFit.contain))
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.qr_code_scanner, size: 40, color: Colors.grey.shade400),
                              const SizedBox(height: 8),
                              Text("Ketuk untuk unggah QRIS", style: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 12)),
                            ],
                          ),
              ),
            ),
            const SizedBox(height: 40),

            // --- TOMBOL SIMPAN ---
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: isSaving ? null : saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: limeGreen, foregroundColor: darkText,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 0,
                ),
                child: isSaving
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF1A1A2E)))
                    : Text('Simpan Perubahan', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // Helper Widget Text Field
  Widget _buildLabeledField({required String label, required TextEditingController controller, required String hintText, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 12, color: subtitleColor)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.poppins(fontSize: 14, color: darkText),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade400),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: tealColor)),
          ),
        ),
      ],
    );
  }
}