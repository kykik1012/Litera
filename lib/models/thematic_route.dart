class ThematicRouteModel {
  final String id;
  final String judulRute;
  final num? panjangRute; // UBAH INI: Tambahkan tanda tanya (?)
  final String deskripsi;
  final bool isDelete; 
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ThematicRouteModel({
    required this.id,
    required this.judulRute,
    this.panjangRute, // UBAH INI: Hilangkan kata 'required'
    required this.deskripsi,
    this.isDelete = false, 
    this.createdAt,
    this.updatedAt,
  });

  factory ThematicRouteModel.fromJson(Map<String, dynamic> json) {
    return ThematicRouteModel(
      id: json['id'].toString(),
      judulRute: json['judul_rute'] as String,
      // UBAH INI: Gunakan 'as num?' agar tidak error jika nilainya null
      panjangRute: json['panjang_rute'] as num?, 
      deskripsi: json['deskripsi'] as String,
      isDelete: json['is_delete'] ?? false, 
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }
}