class ThematicRouteModel {
  final String id;
  final String judulRute;
  final num panjangRute;
  final String deskripsi;
  final bool isDelete; // Tambahan field is_delete
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ThematicRouteModel({
    required this.id,
    required this.judulRute,
    required this.panjangRute,
    required this.deskripsi,
    this.isDelete = false, // Set default false
    this.createdAt,
    this.updatedAt,
  });

  factory ThematicRouteModel.fromJson(Map<String, dynamic> json) {
    return ThematicRouteModel(
      id: json['id'].toString(),
      judulRute: json['judul_rute'] as String,
      panjangRute: json['panjang_rute'] as num,
      deskripsi: json['deskripsi'] as String,
      // Mapping dari JSON
      isDelete: json['is_delete'] ?? false, 
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }
}