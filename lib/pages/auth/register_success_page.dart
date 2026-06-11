import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../main_screen.dart';

class RegisterSuccessPage extends StatelessWidget {
  final String name;

  const RegisterSuccessPage({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    const Color darkText = Color(0xFF1A1A2E);
    const Color subtitleColor = Color(0xFF555555);
    const Color limeGreen = Color(0xFFAEEA00); // Or the same lime green used before

    // Extract first name or use the whole name if it's short
    final firstName = name.split(' ').first;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Very light grey/white background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo
              const SizedBox(height: 24),
              Image.asset(
                'assets/images/logo_litera.png',
                height: 36,
              ),
              
              const Spacer(),
              
              // Illustration
              Image.asset(
                'assets/images/register_success.png',
                height: 240,
                fit: BoxFit.contain,
              ),
              
              const SizedBox(height: 40),
              
              // Title
              Text(
                'Selamat datang, Kak $firstName',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: darkText,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 12),
              
              // Subtitle
              Text(
                'Yay, akun kamu sudah aktif. Sekarang waktunya\njelajahin Litera dan nikmatin fiturnya!',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: subtitleColor,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              const Spacer(),
              
              // Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to home/beranda
                    // Using pushAndRemoveUntil to clear stack so user can't go back to success page
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const MainScreen()),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: limeGreen,
                    foregroundColor: darkText,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    'Ke Beranda',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
