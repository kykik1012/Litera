import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class MerchantScanVoucherPage extends StatefulWidget {
  const MerchantScanVoucherPage({super.key});

  @override
  State<MerchantScanVoucherPage> createState() => _MerchantScanVoucherPageState();
}

class _MerchantScanVoucherPageState extends State<MerchantScanVoucherPage> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _isProcessing = false;
  final Color darkGreen = const Color(0xFF003D33);
  final Color limeGreen = const Color(0xFFAEEA00);

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty || barcodes.first.rawValue == null) return;

    setState(() => _isProcessing = true);
    
    String scanData = barcodes.first.rawValue!;
    String finalVoucherCode = scanData;

    // Coba ekstrak jika QR dalam bentuk JSON (jaga-jaga jika formatnya JSON)
    try {
      Map<String, dynamic> data = jsonDecode(scanData);
      if (data['voucher'] != null) {
        finalVoucherCode = data['voucher'].toString();
      }
    } catch (_) {
      // Jika bukan JSON, berarti itu teks biasa. Biarkan finalVoucherCode = scanData.
    }

    // Kembalikan kode voucher ke halaman sebelumnya
    _scannerController.stop();
    Navigator.pop(context, finalVoucherCode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text("Scan QR Voucher", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),
          ColorFiltered(
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.6), BlendMode.srcOut),
            child: Stack(
              children: [
                Container(decoration: const BoxDecoration(color: Colors.black, backgroundBlendMode: BlendMode.dstOut)),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 250, height: 250,
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 250, height: 250,
            decoration: BoxDecoration(border: Border.all(color: limeGreen, width: 3), borderRadius: BorderRadius.circular(16)),
          ),
          Positioned(
            bottom: 100,
            child: Text(
              "Arahkan kamera ke QR Voucher Pelanggan",
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}