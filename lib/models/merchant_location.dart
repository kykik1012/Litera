class MerchantLocationModel {
  final String id;
  final num latitude;
  final num longitude;
  final String alamat;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String namaBisnis;

  MerchantLocationModel({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.alamat,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
    required this.namaBisnis,
  });

  factory MerchantLocationModel.fromJson(Map<String, dynamic> json) {
    return MerchantLocationModel(
      id: json['id'].toString(),
      latitude: json['latitude'] as num,
      longitude: json['longitude'] as num,
      alamat: json['alamat'] as String,
      isActive: json['is_active'] ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      namaBisnis: json['nama_bisnis'] as String,
    );
  }
}