import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // Untuk kIsWeb
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
// --- 1. TAMBAHKAN IMPORT MODEL ---
import 'package:litera/models/thematic_route.dart'; // Sesuaikan path modelmu
// ---------------------------------
import '../../services/thematic_service.dart';

class TambahRutePage extends StatefulWidget {
  // --- 2. UBAH CONSTRUCTOR AGAR MENERIMA DATA OPSIONAL ---
  final ThematicRouteModel? route; // Jika null = mode tambah, jika berisi = mode edit

  const TambahRutePage({super.key, this.route});
  // ------------------------------------------------------

  @override
  State<TambahRutePage> createState() => _TambahRutePageState();
}

class _TambahRutePageState extends State<TambahRutePage> {
  final _formKey = GlobalKey<FormState>();
  
  // --- 3. JADIKAN CONTROLLER 'LATE' AGAR BISA DIINISIALISASI DI INITSTATE ---
  late TextEditingController _judulController;
  late TextEditingController _deskripsiController;
  // -------------------------------------------------------------------------

  final ThematicRouteService _routeService = ThematicRouteService();
  bool _isLoading = false;

  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  static const Color tealDark = Color(0xFF145C54);
  static const Color limeGreen = Color(0xFFB8E926);

  // --- 4. BUAT HELPER UNTUK MENGECEK MODE ---
  bool get _isEditMode => widget.route != null;
  // ------------------------------------------

  @override
  void initState() {
    super.initState();
    // --- 5. INISIALISASI CONTROLLER BERDASARKAN MODE ---
    _judulController = TextEditingController(text: _isEditMode ? widget.route!.judulRute : '');
    _deskripsiController = TextEditingController(text: _isEditMode ? widget.route!.deskripsi : '');
    // --------------------------------------------------
  }

  @override
  void dispose() {
    _judulController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 80);
      if (pickedFile != null) {
        setState(() => _selectedImage = pickedFile);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal membuka kamera/galeri")));
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("Pilih Sumber Gambar", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: tealDark),
                title: const Text("Kamera"),
                onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: tealDark),
                title: const Text("Galeri"),
                onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
              ),
              if (_selectedImage != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text("Hapus Gambar", style: TextStyle(color: Colors.red)),
                  onTap: () { Navigator.pop(context); setState(() => _selectedImage = null); },
                ),
            ],
          ),
        );
      },
    );
  }

  // --- 6. MEROMBAK FUNGSI SUBMIT (Bisa Create & Update) ---
  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      Uint8List? imageBytes;
      String? fileName;
      if (_selectedImage != null) {
        imageBytes = await _selectedImage!.readAsBytes();
        fileName = _selectedImage!.name;
      }

      Map<String, dynamic> response;

      // Percabangan logika berdasarkan mode
      if (_isEditMode) {
        // Mode EDIT: Panggil updateThematicRoute (Multipart versi PUT)
        // Kita gunakan panjang_rute asli yang ada di data lama
        response = await _routeService.updateThematicRoute(
          widget.route!.id,
          _judulController.text,
          widget.route!.panjangRute ?? 0,
          _deskripsiController.text,
          imageBytes: imageBytes,
          imageFileName: fileName,
        );
      } else {
        // Mode TAMBAH: Panggil createThematicRoute seperti biasa
        response = await _routeService.createThematicRoute(
          _judulController.text,
          0, // panjang_rute default
          _deskripsiController.text,
          imageBytes: imageBytes,
          imageFileName: fileName,
        );
      }

      if (response['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditMode ? "Berhasil memperbarui rute!" : "Berhasil menambahkan rute!")),
        );
        Navigator.pop(context, true); 
      } else {
        throw Exception(response['message'] ?? "Gagal memproses rute");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Terjadi kesalahan: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1A1A2E), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        // --- 7. UBAH JUDUL APPBAR SECARA DINAMIS ---
        title: Text(
          _isEditMode ? "Edit Rute Tematik" : "Tambah Rute Tematik",
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A2E)),
        ),
        // ------------------------------------------
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text("Gambar Utama (Opsional)", style: GoogleFonts.poppins(color: Colors.grey[700], fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _showImageSourceDialog,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _selectedImage != null ? limeGreen : Colors.grey.shade300, width: 2),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              kIsWeb ? Image.network(_selectedImage!.path, fit: BoxFit.cover) : Image.file(File(_selectedImage!.path), fit: BoxFit.cover),
                              Container(color: Colors.black.withOpacity(0.3), child: const Icon(Icons.edit, color: Colors.white, size: 30))
                            ],
                          ),
                        )
                      // --- 8. LOGIKA TAMPILAN GAMBAR SAAT EDIT (Opsional) ---
                      // Jika di mode edit dan rute lama punya gambar (asumsi ada field imageUrl),
                      // kamu bisa menampilkan gambar lamanya di sini.
                      // Jika model belum ada imageUrl, biarkan instruksi unggah biasa ini.
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, color: Colors.grey.shade400, size: 50),
                            const SizedBox(height: 8),
                            Text(
                              _isEditMode ? "Ketuk untuk mengganti gambar" : "Ketuk untuk unggah gambar", 
                              style: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 13)
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _judulController,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: InputDecoration(
                  labelText: "Judul Rute",
                  filled: true, fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: tealDark, width: 1.5)),
                ),
                validator: (value) => (value == null || value.trim().isEmpty) ? "Judul rute tidak boleh kosong" : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _deskripsiController,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: InputDecoration(
                  labelText: "Deskripsi",
                  filled: true, fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: tealDark, width: 1.5)),
                ),
                maxLines: 4,
                validator: (value) => (value == null || value.trim().isEmpty) ? "Deskripsi tidak boleh kosong" : null,
              ),
              const SizedBox(height: 32),

              // --- 9. UBAH TEKS TOMBOL SECARA DINAMIS ---
              ElevatedButton(
                onPressed: _isLoading ? null : _submitData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: tealDark, foregroundColor: limeGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: limeGreen, strokeWidth: 2))
                    : Text(
                        _isEditMode ? "Simpan Perubahan" : "Simpan Rute", 
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}