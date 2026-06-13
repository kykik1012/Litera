import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/auth_service.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;

  const ResetPasswordPage({super.key, required this.email});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final otpController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  final _otpFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _isPasswordHidden = true;
  bool _isConfirmHidden = true;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _otpFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
    _confirmFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    otpController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    _otpFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> resetPassword() async {
    if (otpController.text.isEmpty || passwordController.text.isEmpty || confirmController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Semua kolom harus diisi")));
      return;
    }

    if (passwordController.text != confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Konfirmasi password tidak sama")));
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await AuthService().resetPassword(
        email: widget.email,
        otp: otpController.text,
        newPassword: passwordController.text,
      );

      if (response["success"] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password berhasil direset")));
        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response["message"])));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }

    if (mounted) setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    const Color bgColor = Color.fromARGB(255, 255, 255, 255);
    const Color tealColor = Color(0xFF1A7A6D);
    const Color darkText = Color(0xFF1A1A2E);
    const Color subtitleColor = Color(0xFF6B7280);
    const Color inputHintColor = Color(0xFFA0AEC0);
    const Color underlineColor = Color(0xFFD1D5DB);
    const Color activeUnderlineColor = Color(0xFF1A7A6D);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: darkText, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(
                  'Buat Password Baru',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: darkText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Masukkan kode OTP yang telah dikirim ke email Anda beserta password baru yang ingin Anda gunakan.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: subtitleColor,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),

                // OTP
                TextField(
                  controller: otpController,
                  focusNode: _otpFocus,
                  style: GoogleFonts.poppins(fontSize: 15, color: darkText),
                  decoration: InputDecoration(
                    hintText: 'Kode OTP',
                    hintStyle: GoogleFonts.poppins(fontSize: 15, color: inputHintColor),
                    suffixIcon: Icon(
                      Icons.pin_outlined,
                      color: _otpFocus.hasFocus ? tealColor : inputHintColor,
                      size: 22,
                    ),
                    border: InputBorder.none,
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: underlineColor, width: 1),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: activeUnderlineColor, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 24),

                // Password Baru
                TextField(
                  controller: passwordController,
                  focusNode: _passwordFocus,
                  obscureText: _isPasswordHidden,
                  style: GoogleFonts.poppins(fontSize: 15, color: darkText),
                  decoration: InputDecoration(
                    hintText: 'Password Baru',
                    hintStyle: GoogleFonts.poppins(fontSize: 15, color: inputHintColor),
                    suffixIcon: GestureDetector(
                      onTap: () => setState(() => _isPasswordHidden = !_isPasswordHidden),
                      child: Icon(
                        _isPasswordHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: _passwordFocus.hasFocus ? tealColor : inputHintColor,
                        size: 22,
                      ),
                    ),
                    border: InputBorder.none,
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: underlineColor, width: 1),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: activeUnderlineColor, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 24),

                // Konfirmasi Password
                TextField(
                  controller: confirmController,
                  focusNode: _confirmFocus,
                  obscureText: _isConfirmHidden,
                  style: GoogleFonts.poppins(fontSize: 15, color: darkText),
                  decoration: InputDecoration(
                    hintText: 'Konfirmasi Password',
                    hintStyle: GoogleFonts.poppins(fontSize: 15, color: inputHintColor),
                    suffixIcon: GestureDetector(
                      onTap: () => setState(() => _isConfirmHidden = !_isConfirmHidden),
                      child: Icon(
                        _isConfirmHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: _confirmFocus.hasFocus ? tealColor : inputHintColor,
                        size: 22,
                      ),
                    ),
                    border: InputBorder.none,
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: underlineColor, width: 1),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: activeUnderlineColor, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 48),

                // Simpan Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : resetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tealColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Simpan & Masuk',
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
      ),
    );
  }
}
