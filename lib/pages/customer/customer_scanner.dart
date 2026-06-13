import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../services/merchant_service.dart';
import '../../models/merchant.dart';
import 'customer_merchant_detail_page.dart'; // Sesuaikan path ini jika perlu

class CustomerScannerPage extends StatefulWidget {
  const CustomerScannerPage({super.key});

  @override
  State<CustomerScannerPage> createState() => _CustomerScannerPageState();
}

class _CustomerScannerPageState extends State<CustomerScannerPage> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  final MerchantService _merchantService = MerchantService();
  
  bool _isProcessing = false; // Mencegah scan berulang kali
  final Color darkGreen = const Color(0xFF003D33);
  final Color limeGreen = const Color(0xFFAEEA00);

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  // --- LOGIKA UTAMA SAAT QR BERHASIL DIBACA ---
  Future<void> _onDetect(BarcodeCapture capture) async {
    // Jika sedang memproses data, abaikan hasil scan yang masuk
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty || barcodes.first.rawValue == null) return;

    final String scanData = barcodes.first.rawValue!;
    
    // Kunci proses agar tidak double-scan
    setState(() => _isProcessing = true);

    try {
      // 1. Coba baca teks hasil scan sebagai JSON
      Map<String, dynamic> data = jsonDecode(scanData);

      // 2. Cek apakah ini benar-benar QR Toko Litera
      if (data['tipe'] == 'toko_litera' && data['merchant_id'] != null) {
        String targetMerchantId = data['merchant_id'].toString();

        // Tampilkan indikator loading di layar
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => Center(child: CircularProgressIndicator(color: limeGreen)),
        );

        // 3. Tarik data seluruh merchant dari API
        final response = await _merchantService.getAllMerchants();

        if (!mounted) return;
        Navigator.pop(context); // Tutup indikator loading

        if (response['success'] == true) {
          final List<dynamic> merchantList = response['data'];
          
          // 4. Cari toko yang ID-nya cocok dengan QR Code
          final targetData = merchantList.firstWhere(
            (m) => m['id'].toString() == targetMerchantId, 
            orElse: () => null
          );

          if (targetData != null) {
            MerchantModel targetMerchant = MerchantModel.fromJson(targetData);
            
            // 5. Bawa customer masuk ke halaman Detail Toko!
            // Kita matikan sementara kamera agar tidak berat saat di background
            _scannerController.stop(); 
            
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CustomerMerchantDetailPage(merchant: targetMerchant),
              ),
            );
            
            // Nyalakan kembali kamera jika pengguna kembali ke halaman ini
            _scannerController.start();
            setState(() => _isProcessing = false);
            return;
            
          } else {
             _showErrorSnackBar("Toko tidak ditemukan atau sudah tutup.");
          }
        } else {
          _showErrorSnackBar("Gagal mengambil data dari server.");
        }
      } else {
        _showErrorSnackBar("QR Code tidak valid untuk aplikasi Litera.");
      }
    } catch (e) {
      // Jika teks yang discan bukan format JSON
      debugPrint("Format QR tidak dikenali: $scanData");
      _showErrorSnackBar("Mohon scan QR Code Toko Litera yang valid.");
    }

    // Buka kunci proses setelah 2 detik agar pengguna bisa mencoba scan lagi
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isProcessing = false);
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text(
          "Pindai QR Toko",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _scannerController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => _scannerController.switchCamera(),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Kamera Scanner
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),
          
          // 2. Overlay Gelap di luar area kotak scan
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.6),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      color: Colors.red, // Warna ini akan jadi transparan karena BlendMode.dstOut
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 3. Garis Frame Scanner
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: limeGreen, width: 3),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          
          // 4. Teks Bantuan di bawah frame
          Positioned(
            bottom: 120,
            child: Text(
              _isProcessing ? "Memproses..." : "Arahkan kamera ke QR Code Toko",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}