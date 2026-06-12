import 'dart:io'; 
import 'dart:typed_data'; 
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // <--- 1. TAMBAHAN UNTUK MENDETEKSI WEB (kIsWeb)
import 'package:image_picker/image_picker.dart'; 
import '../../models/merchant.dart';
import '../../services/review_service.dart';

class CustomerAddReviewPage extends StatefulWidget {
  final MerchantModel merchant;

  const CustomerAddReviewPage({
    super.key,
    required this.merchant,
  });

  @override
  State<CustomerAddReviewPage> createState() => _CustomerAddReviewPageState();
}

class _CustomerAddReviewPageState extends State<CustomerAddReviewPage> {
  final TextEditingController _reviewController = TextEditingController();
  int _selectedRating = 5; 
  bool _isSubmitting = false;

  // --- 2. UBAH DARI File? MENJADI XFile? AGAR MENDUKUNG WEB & MOBILE ---
  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  final Color darkGreen = const Color(0xFF003D33);
  final Color limeGreen = const Color(0xFFAEEA00);

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  // --- FUNGSI MENGAMBIL FOTO ---
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80, 
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = pickedFile; // Simpan sebagai XFile
        });
      }
    } catch (e) {
      debugPrint("Gagal mengambil foto: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal membuka kamera/galeri")),
      );
    }
  }

  // --- DIALOG PILIHAN SUMBER FOTO ---
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("Pilih Sumber Foto", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF003D33)),
                title: const Text("Kamera"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF003D33)),
                title: const Text("Galeri"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_selectedImage != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text("Hapus Foto", style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _selectedImage = null);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitReview() async {
    if (_reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ulasan tidak boleh kosong!")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      Uint8List? imageBytes;
      String? fileName;
      
      if (_selectedImage != null) {
        imageBytes = await _selectedImage!.readAsBytes();
        fileName = _selectedImage!.name; // Gunakan .name bawaan XFile
      }

      final response = await ReviewService().createReview(
        merchantId: int.parse(widget.merchant.id),
        rating: _selectedRating,
        deskripsi: _reviewController.text,
        imageBytes: imageBytes,
        imageFileName: fileName,
      );

      if (response['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Berhasil mengirim ulasan!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); 
      } else {
        throw Exception(response['message'] ?? "Gagal menyimpan data ke server");
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal mengirim: $e")),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        backgroundColor: darkGreen,
        foregroundColor: Colors.white,
        title: const Text("Tulis Ulasan"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Bagaimana pengalamanmu di ${widget.merchant.namaBisnis}?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkGreen),
            ),
            const SizedBox(height: 32),
            
            // 1. INPUT BINTANG (RATING)
            const Text("Berikan Penilaian:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () => setState(() => _selectedRating = index + 1),
                  icon: Icon(
                    index < _selectedRating ? Icons.star_rounded : Icons.star_border_rounded,
                    color: Colors.amber,
                    size: 48,
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),

            // 2. INPUT TEKS DESKRIPSI
            const Text("Tuliskan Ulasanmu:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _reviewController,
              maxLines: 5,
              decoration: InputDecoration(
                fillColor: Colors.white,
                filled: true,
                hintText: "Ceritakan pengalamanmu tentang rasa, pelayanan, atau suasananya...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: limeGreen, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 3. INPUT FOTO ULASAN (KAMERA/GALERI)
            const Text("Tambahkan Foto (Opsional):", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _showImageSourceDialog,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _selectedImage != null ? limeGreen : Colors.grey.shade400, width: 2),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // --- 3. LOGIKA UNTUK WEB DAN HP DISINI ---
                            kIsWeb 
                                // Jika di Web (Chrome), gunakan Image.network untuk membaca blob URL
                                ? Image.network(_selectedImage!.path, fit: BoxFit.cover)
                                // Jika di HP Asli/Emulator, gunakan Image.file
                                : Image.file(File(_selectedImage!.path), fit: BoxFit.cover),
                            // -----------------------------------------
                            Container(
                              color: Colors.black.withOpacity(0.3),
                              child: const Icon(Icons.edit, color: Colors.white, size: 30),
                            )
                          ],
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, color: darkGreen, size: 40),
                          const SizedBox(height: 8),
                          const Text("Ketuk untuk unggah foto", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 40),

            // 4. TOMBOL KIRIM
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkGreen,
                  foregroundColor: limeGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Kirim Ulasan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}