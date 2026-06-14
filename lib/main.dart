import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:device_preview/device_preview.dart'; // 1. Pastikan import ini ditambahkan

import 'pages/auth/onboarding_page.dart';
import 'pages/splash_screen_page.dart';

void main() {
  runApp(
    DevicePreview(
      enabled: true, // Ubah ke false jika ingin mematikan preview
      builder: (context) => const MyApp(), // Menggunakan MyApp
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ),
      ),

      // 2. Konfigurasi tambahan untuk Device Preview
      builder: DevicePreview.appBuilder,
      locale: DevicePreview.locale(context),

      // 3. Menggunakan SplashScreenPage sebagai halaman utama
      home: const SplashScreenPage(),
    );
  }
}
