import 'dart:async';
import 'package:flutter/material.dart';
import 'auth/onboarding_page.dart';

class SplashScreenPage extends StatefulWidget {
  const SplashScreenPage({super.key});

  @override
  State<SplashScreenPage> createState() => _SplashScreenPageState();
}

class _SplashScreenPageState extends State<SplashScreenPage> {
  @override
  void initState() {
    super.initState();
    // Berpindah ke OnboardingPage setelah 5 detik
    Timer(const Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomPaint(
        painter: _SplashBackgroundPainter(),
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Center(
            child: Image.asset(
              'assets/images/logo_splashscreen.png',
              width: 140, // Sesuaikan ukuran logo di sini
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // 1. Warna dasar lime green
    paint.color = const Color(0xFF8CE309);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // 2. Lengkungan atas (hijau sedikit lebih muda/berbeda)
    paint.color = const Color(0xFFA1F016).withOpacity(0.5);
    final path1 = Path();
    path1.moveTo(0, size.height * 0.15);
    path1.quadraticBezierTo(
        size.width * 0.4, size.height * 0.45, size.width, size.height * 0.2);
    path1.lineTo(size.width, 0);
    path1.lineTo(0, 0);
    path1.close();
    canvas.drawPath(path1, paint);

    // 3. Lengkungan bawah 1 (agak gelap)
    paint.color = const Color(0xFF7BC612).withOpacity(0.6);
    final path2 = Path();
    path2.moveTo(0, size.height * 0.5);
    path2.quadraticBezierTo(
        size.width * 0.5, size.height * 0.8, size.width, size.height * 0.45);
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, paint);

    // 4. Lengkungan bawah 2 (paling bawah, hijau kekuningan)
    paint.color = const Color(0xFF98EB18).withOpacity(0.8);
    final path3 = Path();
    path3.moveTo(0, size.height * 0.7);
    path3.quadraticBezierTo(
        size.width * 0.4, size.height * 0.95, size.width, size.height * 0.75);
    path3.lineTo(size.width, size.height);
    path3.lineTo(0, size.height);
    path3.close();
    canvas.drawPath(path3, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
