class PromotionModel {
  final String id;
  final String productId;   // <--- BARU
  final String merchantId;  // <--- BARU
  final String tipePromo;
  final num diskon;
  final int kuota;
  final DateTime? tanggalBerlaku;
  final DateTime? tanggalExpired;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isDelete;      // <--- BARU
  final String namaProduk;
  final String namaBisnis;

  PromotionModel({
    required this.id,
    required this.productId,
    required this.merchantId,
    required this.tipePromo,
    required this.diskon,
    required this.kuota,
    this.tanggalBerlaku,
    this.tanggalExpired,
    this.createdAt,
    this.updatedAt,
    required this.isDelete,
    required this.namaProduk,
    required this.namaBisnis,
  });

  factory PromotionModel.fromJson(Map<String, dynamic> json) {
    return PromotionModel(
      id: json['id'].toString(),
      productId: json['product_id']?.toString() ?? '',
      merchantId: json['merchant_id']?.toString() ?? '',
      tipePromo: json['tipe_promo']?.toString() ?? 'PROMO',
      diskon: json['diskon'] ?? 0,
      kuota: json['kuota'] ?? 0,
      tanggalBerlaku: json['tanggal_berlaku'] != null ? DateTime.tryParse(json['tanggal_berlaku'].toString()) : null,
      tanggalExpired: json['tanggal_expired'] != null ? DateTime.tryParse(json['tanggal_expired'].toString()) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
      isDelete: json['is_delete'] == true, // Format boolean
      namaProduk: json['nama_produk']?.toString() ?? 'Produk',
      namaBisnis: json['nama_bisnis']?.toString() ?? 'Toko',
    );
  }

  // Pengecekan promo masih valid
  bool get isValid {
    if (isDelete) return false; // Jangan tampilkan jika sudah dihapus
    if (kuota <= 0) return false;
    if (tanggalExpired != null && DateTime.now().isAfter(tanggalExpired!)) {
      return false;
    }
    return true; 
  }
}