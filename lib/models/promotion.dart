class PromotionModel {
  final String id;
  final String tipePromo;
  final num diskon;
  final int kuota;
  final DateTime? tanggalBerlaku;
  final DateTime? tanggalExpired;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String namaProduk;
  final String namaBisnis;

  PromotionModel({
    required this.id,
    required this.tipePromo,
    required this.diskon,
    required this.kuota,
    this.tanggalBerlaku,
    this.tanggalExpired,
    this.createdAt,
    this.updatedAt,
    required this.namaProduk,
    required this.namaBisnis,
  });

  factory PromotionModel.fromJson(Map<String, dynamic> json) {
    return PromotionModel(
      id: json['id'].toString(),
      tipePromo: json['tipe_promo'] as String,
      diskon: json['diskon'] as num,
      kuota: json['kuota'] as int,
      tanggalBerlaku: json['tanggal_berlaku'] != null ? DateTime.parse(json['tanggal_berlaku']) : null,
      tanggalExpired: json['tanggal_expired'] != null ? DateTime.parse(json['tanggal_expired']) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      namaProduk: json['nama_produk'] as String,
      namaBisnis: json['nama_bisnis'] as String,
    );
  }
}