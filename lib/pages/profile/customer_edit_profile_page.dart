import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../helpers/shared_pref_helper.dart';
import '../../services/user_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final userService = UserService();

  bool isLoading = true;
  bool isSaving = false;

  int userId = 0;

  File? selectedImage;
  String? profilePicture;

  final nameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool _isPasswordHidden = true;
  bool _isConfirmPasswordHidden = true;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    userId = await SharedPrefHelper.getUserId() ?? 0;

    final response = await userService.getUserById(userId);

    if (response["success"] == true) {
      final data = response["data"];
      profilePicture = data["profile_picture"];

      if (role == 2) {
        nameController.text = data["name"] ?? "";
      } else {
        namaBisnisController.text = data["nama_bisnis"] ?? "";
        deskripsiController.text = data["deskripsi"] ?? "";
        tahunController.text = data["usaha_didirikan"]?.toString() ?? "";
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    setState(() {
      selectedImage = File(image.path);
    });
  }

  Future<void> saveProfile() async {
    // Validasi konfirmasi password
    if (passwordController.text.isNotEmpty || confirmPasswordController.text.isNotEmpty) {
      if (passwordController.text != confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Konfirmasi password tidak sesuai")),
        );
        return;
      }
    }

    setState(() => isSaving = true);

    try {
      if (selectedImage != null) {
        await userService.uploadProfilePicture(
          id: userId,
          image: selectedImage!,
        );
      }

      Map<String, dynamic> response;

      if (role == 2) {
        response = await userService.updateCustomer(
          id: userId,
          name: nameController.text,
        );
      } else {
        response = await userService.updateMerchant(
          id: userId,
          namaBisnis: namaBisnisController.text,
          deskripsi: deskripsiController.text,
          usahaDidirikan: tahunController.text,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response["message"])),
      );

      if (response["success"] == true) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color bgColor = Color.fromARGB(255, 255, 255, 255);
    const Color darkText = Color(0xFF1A1A2E);
    const Color subtitleColor = Color(0xFF6B7280);
    const Color tealColor = Color(0xFF1A7A6D);
    const Color inputHintColor = Color(0xFFA0AEC0);
    const Color underlineColor = Color(0xFFD1D5DB);
    const Color limeGreen = Color(0xFFB8E926);
    const Color bannerBg = Color(0xFFD4F0ED);
    const Color bannerText = Color(0xFF145C54);

    if (isLoading) {
      return const Scaffold(
        backgroundColor: bgColor,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Custom App Bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.chevron_left_rounded, size: 28, color: darkText),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Edit Profil',
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: darkText),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), 
                ],
              ),
            ),

            // ── Scrollable Content ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // ── Info Banner ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: bannerBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Cek datamu dan ubah jika perlu, lalu klik "Simpan".',
                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w400, color: bannerText),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Data Akun heading ──
                    Text(
                      'Data Akun',
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: darkText),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pastikan Anda mengisi data dengan benar sebelum menyimpan, yaa.',
                      style: GoogleFonts.poppins(fontSize: 13, color: subtitleColor, height: 1.5),
                    ),
                    const SizedBox(height: 24),

                    // ── Avatar with Edit ──
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: pickImage,
                            child: Container(
                              width: 90, height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFD4F0ED),
                                border: Border.all(color: const Color(0xFFB8E0DB), width: 2),
                              ),
                              child: ClipOval(
                                child: selectedImage != null
                                    ? Image.file(selectedImage!, fit: BoxFit.cover, width: 90, height: 90)
                                    : profilePicture != null
                                        ? Image.network(
                                            profilePicture!, fit: BoxFit.cover, width: 90, height: 90,
                                            errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 44, color: Color(0xFF145C54)),
                                          )
                                        : const Icon(Icons.person, size: 44, color: Color(0xFF145C54)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: pickImage,
                            child: Text(
                              'Edit',
                              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: darkText),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Form Fields ──
                    _buildLabeledField(
                      label: 'Nama Lengkap',
                      controller: nameController,
                      hintText: 'Masukkan nama lengkap',
                      suffixIcon: const Icon(Icons.person_outline, color: inputHintColor, size: 22),
                      darkText: darkText,
                      inputHintColor: inputHintColor,
                      underlineColor: underlineColor,
                      tealColor: tealColor,
                      subtitleColor: subtitleColor,
                    ),
                    const SizedBox(height: 20),

                    // Kata Sandi field
                    _buildLabeledField(
                      label: 'Kata Sandi',
                      controller: passwordController,
                      hintText: 'Masukkan kata sandi baru (Opsional)',
                      obscureText: _isPasswordHidden,
                      suffixIcon: GestureDetector(
                        onTap: () => setState(() => _isPasswordHidden = !_isPasswordHidden),
                        child: Icon(
                          _isPasswordHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: inputHintColor, size: 22,
                        ),
                      ),
                      darkText: darkText,
                      inputHintColor: inputHintColor,
                      underlineColor: underlineColor,
                      tealColor: tealColor,
                      subtitleColor: subtitleColor,
                    ),
                    const SizedBox(height: 20),

                    // Konfirmasi Kata Sandi field
                    _buildLabeledField(
                      label: 'Konfirmasi Kata Sandi',
                      controller: confirmPasswordController,
                      hintText: 'Konfirmasi kata sandi baru',
                      obscureText: _isConfirmPasswordHidden,
                      suffixIcon: GestureDetector(
                        onTap: () => setState(() => _isConfirmPasswordHidden = !_isConfirmPasswordHidden),
                        child: Icon(
                          _isConfirmPasswordHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: inputHintColor, size: 22,
                        ),
                      ),
                      darkText: darkText,
                      inputHintColor: inputHintColor,
                      underlineColor: underlineColor,
                      tealColor: tealColor,
                      subtitleColor: subtitleColor,
                    ),
                    const SizedBox(height: 40),

                    // ── Simpan button ──
                    SizedBox(
                      width: double.infinity, height: 52,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: limeGreen,
                          disabledBackgroundColor: limeGreen.withOpacity(0.5),
                          foregroundColor: darkText,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: isSaving
                            ? const SizedBox(
                                height: 22, width: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF1A1A2E)),
                              )
                            : Text(
                                'Simpan',
                                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: darkText),
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper to build a labeled underline field matching the design
  Widget _buildLabeledField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required Color darkText,
    required Color inputHintColor,
    required Color underlineColor,
    required Color tealColor,
    required Color subtitleColor,
    Widget? suffixIcon,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w400, color: subtitleColor),
        ),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: GoogleFonts.poppins(fontSize: 15, color: darkText),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.poppins(fontSize: 15, color: inputHintColor),
            suffixIcon: suffixIcon,
            border: InputBorder.none,
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: underlineColor, width: 1)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: tealColor, width: 2)),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }
}