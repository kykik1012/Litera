class MerchantModel {
  final String id;
  final String userId;
  final String namaBisnis;
  
  // --- PERUBAHAN BARU ---
  final DateTime? usahaDidirikan; // Menggantikan tahunBerdiri
  final String? jamBuka;          // Fitur Baru
  final String? jamTutup;         // Fitur Baru
  final String? imageQr;          // Fitur Baru
  // ----------------------
  
  final String? deskripsi;
  final String? imageUrl;
  final String status;
  final String? profilePicture;
  final double? latitude;
  final double? longitude;

  MerchantModel({
    required this.id,
    required this.userId,
    required this.namaBisnis,
    this.usahaDidirikan,
    this.jamBuka,
    this.jamTutup,
    this.imageQr,
    this.deskripsi,
    this.imageUrl,
    required this.status,
    this.profilePicture,
    this.latitude,
    this.longitude,
  });

  factory MerchantModel.fromJson(Map<String, dynamic> json) {
    return MerchantModel(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      namaBisnis: json['nama_bisnis'] ?? '',
      
      // --- PENYESUAIAN JSON BARU ---
      usahaDidirikan: json['usaha_didirikan'] != null 
          ? DateTime.tryParse(json['usaha_didirikan'].toString()) 
          : null,
      jamBuka: json['jam_buka']?.toString(),
      jamTutup: json['jam_tutup']?.toString(),
      imageQr: json['image_qr']?.toString(),
      // -----------------------------
      
      deskripsi: json['deskripsi']?.toString(),
      imageUrl: json['image_url']?.toString(),
      status: json['status']?.toString() ?? 'Tutup',
      profilePicture: json['profile_picture']?.toString(),
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
    );
  }
}