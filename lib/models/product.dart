class ProductModel {
  final String id;
  final String namaProduk;
  final num hargaProduk;
  final String deskripsi;
  final String? imageUrl;
  final bool isAvailable;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String namaBisnis;
  final int? categoryId;
  final bool isActive;

  ProductModel({
    required this.id,
    required this.namaProduk,
    required this.hargaProduk,
    required this.deskripsi,
    this.imageUrl,
    required this.isAvailable,
    this.createdAt,
    this.updatedAt,
    required this.namaBisnis,
    this.categoryId,
    this.isActive = true,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'].toString(),
      namaProduk: json['nama_produk'] as String,
      hargaProduk: json['harga_produk'] as num,
      deskripsi: json['deskripsi'] as String,
      imageUrl: json['image_url'] as String?,
      isAvailable: json['is_available'] ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      namaBisnis: json['nama_bisnis'] as String,
      categoryId: json['category_id'] != null ? int.tryParse(json['category_id'].toString()) : null,
      isActive: json['is_active'] ?? true,
    );
  }
}