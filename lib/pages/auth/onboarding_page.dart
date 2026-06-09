import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // PERUBAHAN: Import google_fonts

import 'login_page.dart';
import 'register_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _slides = [
    OnboardingData(
      image: 'assets/images/onboarding_1.png',
      title: 'Jelajahi Cerita, Bukan Sekadar Titik Peta.',
      description:
          'Dari legenda kuliner hingga bengkel kriya, setiap sudut punya narasi yang menanti Anda buka.',
    ),
    OnboardingData(
      image: 'assets/images/onboarding_2.png',
      title: 'Selamatkan Rasa, Dukung UMKM Lokal',
      description:
          'Nikmati penawaran eksklusif "Rasa Kilat" di sekitar Anda. Dapatkan harga spesial harian produk lokal.',
    ),
    OnboardingData(
      image: 'assets/images/onboarding_3.png',
      title: 'Kumpulkan Jejak, Jadi Penjaga Budaya',
      description:
          'Setiap kunjungan adalah pencapaian. tukarkan badge eksklusif Anda dengan hadiah asli daerah.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Logo Header
            Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 8),
              child: Image.asset(
                'assets/images/logo_litera.png', // Nama dan jalur file gambar baru Anda
                height:
                    36, // Sesuaikan tinggi logo agar pas dengan layout header
                fit: BoxFit
                    .contain, // Memastikan gambar proporsional dan tidak gepeng
              ),
            ),

            // PageView for slides
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  return _buildSlide(_slides[index]);
                },
              ),
            ),

            // Dot Indicators
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (index) => _buildDotIndicator(index),
                ),
              ),
            ),

            // Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  // Daftar Sekarang Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC5E636),
                        foregroundColor: const Color(0xFF1A3A1A),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Text(
                        'Daftar Sekarang',
                        // PERUBAHAN: Menggunakan Poppins untuk tombol
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Masuk Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1A3A1A),
                        side: const BorderSide(
                          color: Color(0xFFC5E636),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Text(
                        'Masuk',
                        // PERUBAHAN: Menggunakan Poppins untuk tombol
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

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // Widget _buildLiteraLogo() {
  //   return Container(
  //     width: 36,
  //     height: 36,
  //     decoration: const BoxDecoration(
  //       color: Color(0xFF1B7A4A),
  //       shape: BoxShape.circle,
  //     ),
  //     child: Center(
  //       child: Text(
  //         '\\',
  //         // PERUBAHAN: Menggunakan Poppins untuk backslash di logo agar konsisten
  //         style: GoogleFonts.poppins(
  //           color: const Color(0xFFC5E636),
  //           fontSize: 22,
  //           fontWeight: FontWeight.bold,
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildSlide(OnboardingData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration / Gambar Onboarding
          Expanded(
            flex: 7,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Image.asset(
                data.image,
                fit: BoxFit.contain,
                width: double.infinity,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Title (Judul)
          Text(
            data.title,
            textAlign: TextAlign.center,
            // PERUBAHAN: Menggunakan GoogleFonts.poppins untuk Judul
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A1A),
              height: 1.3,
            ),
          ),

          const SizedBox(height: 12),

          // Description (Deskripsi)
          Text(
            data.description,
            textAlign: TextAlign.center,
            // PERUBAHAN: Menggunakan GoogleFonts.poppins untuk Deskripsi
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF6B6B6B),
              height: 1.5,
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDotIndicator(int index) {
    final bool isActive = _currentPage == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 28 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFC5E636) : const Color(0xFFD9D9D9),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class OnboardingData {
  final String image;
  final String title;
  final String description;

  const OnboardingData({
    required this.image,
    required this.title,
    required this.description,
  });
}
