import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../helpers/shared_pref_helper.dart';
import '../../services/auth_service.dart';

class MerchantChangePasswordPage extends StatefulWidget {
  const MerchantChangePasswordPage({super.key});

  @override
  State<MerchantChangePasswordPage> createState() => _MerchantChangePasswordPageState();
}

class _MerchantChangePasswordPageState extends State<MerchantChangePasswordPage> {
  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool _isOldPasswordHidden = true;
  bool _isNewPasswordHidden = true;
  bool _isConfirmPasswordHidden = true;
  bool isLoading = false;

  static const Color tealDark = Color(0xFF0D3B2E);
  static const Color limeGreen = Color(0xFFAEEA00);
  static const Color scaffoldBg = Color(0xFFF8F9FA);

  Future<void> changePassword() async {
    if (oldPasswordController.text.isEmpty || newPasswordController.text.isEmpty || confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Semua kolom harus diisi")));
      return;
    }

    if (newPasswordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Konfirmasi kata sandi tidak sama")));
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final userId = await SharedPrefHelper.getUserId();
      final response = await AuthService().changePassword(
        userId: userId ?? 0,
        oldPassword: oldPasswordController.text,
        newPassword: newPasswordController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response["message"])));

      if (response["success"] == true) {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }

    setState(() {
      isLoading = false;
    });
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
          'Ganti Kata Sandi',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Perbarui Kata Sandi Anda',
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildPasswordField('Kata Sandi Lama', oldPasswordController, _isOldPasswordHidden, () => setState(() => _isOldPasswordHidden = !_isOldPasswordHidden)),
              const SizedBox(height: 16),
              _buildPasswordField('Kata Sandi Baru', newPasswordController, _isNewPasswordHidden, () => setState(() => _isNewPasswordHidden = !_isNewPasswordHidden)),
              const SizedBox(height: 16),
              _buildPasswordField('Konfirmasi Kata Sandi Baru', confirmPasswordController, _isConfirmPasswordHidden, () => setState(() => _isConfirmPasswordHidden = !_isConfirmPasswordHidden)),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: limeGreen,
                    foregroundColor: tealDark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: tealDark, strokeWidth: 2))
                      : Text(
                          'Simpan Kata Sandi',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller, bool isHidden, VoidCallback toggle) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextField(
        controller: controller,
        obscureText: isHidden,
        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[800]),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintText: label,
          hintStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[400]),
          suffixIcon: GestureDetector(
            onTap: toggle,
            child: Icon(isHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey[400], size: 20),
          ),
        ),
      ),
    );
  }
}
