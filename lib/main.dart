import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- 1. TAMBAHKAN IMPORT INI ---
import 'package:intl/date_symbol_data_local.dart';

import 'pages/auth/onboarding_page.dart';
import 'pages/splash_screen_page.dart';

// --- 2. UBAH main() MENJADI async ---
void main() async {
  // --- 3. TAMBAHKAN DUA BARIS INI ---
  WidgetsFlutterBinding.ensureInitialized(); 
  await initializeDateFormatting('id_ID', null); 

  // Langsung jalankan MyApp tanpa bungkus DevicePreview
  runApp(const MyApp()); 
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
      // Konfigurasi builder dan locale milik DevicePreview sudah dihapus dari sini

      // Menggunakan SplashScreenPage sebagai halaman utama
      home: const SplashScreenPage(),
    );
  }
}