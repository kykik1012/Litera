class MerchantModel {
  final String id;
  final String userId;
  final String namaBisnis;
  final String? usahaDidirikan;
  final String? jamBuka;
  final String? jamTutup;
  final String? deskripsi;
  final String? profilePicture;
  final String? imageUrl;
  final String? imageQr;
  final num? latitude;
  final num? longitude;
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
    this.deskripsi,
    this.imageUrl,
    required this.status,
    this.profilePicture,
    this.imageUrl,
    this.imageQr,
    this.latitude,
    this.longitude,
  });

  factory MerchantModel.fromJson(Map<String, dynamic> json) {
    return MerchantModel(
      id: json['id'].toString(), 
      userId: json['user_id'].toString(),
      namaBisnis: json['nama_bisnis'] as String,
      usahaDidirikan: json['usaha_didirikan']?.toString(),
      jamBuka: json['jam_buka']?.toString(),
      jamTutup: json['jam_tutup']?.toString(),
      deskripsi: json['deskripsi'] as String?,
      profilePicture: json['profile_picture'] as String?,
      imageUrl: json['image_url'] as String?,
      imageQr: json['image_qr'] as String?,
      latitude: json['latitude'] as num?,
      longitude: json['longitude'] as num?,
      status: json['status']?.toString() ?? 'Tutup',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'nama_bisnis': namaBisnis,
      'usaha_didirikan': usahaDidirikan,
      'jam_buka': jamBuka,
      'jam_tutup': jamTutup,
      'deskripsi': deskripsi,
      'profile_picture': profilePicture,
      'image_url': imageUrl,
      'image_qr': imageQr,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
    };
  }
}