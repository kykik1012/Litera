class ReviewModel {
  final String id;
  final String customerId; // <--- 1. TAMBAHAN BARU
  final num rating;
  final String deskripsi;
  final String? imageUrl;
  final DateTime? submittedAt;
  final String customerName;
  final String namaBisnis;
  final bool isDelete; 

  ReviewModel({
    required this.id,
    required this.customerId, // <--- 2. TAMBAHKAN DI SINI
    required this.rating,
    required this.deskripsi,
    this.imageUrl,
    this.submittedAt,
    required this.customerName,
    required this.namaBisnis,
    this.isDelete = false,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'].toString(),
      customerId: json['customer_id'].toString(), // <--- 3. AMBIL DARI JSON
      rating: json['rating'] as num, 
      deskripsi: json['deskripsi'] as String,
      imageUrl: json['image_url'] as String?,
      submittedAt: json['submitted_at'] != null ? DateTime.parse(json['submitted_at']) : null,
      customerName: json['customer_name'] as String,
      namaBisnis: json['nama_bisnis'] as String,
      isDelete: json['is_delete'] ?? false, 
    );
  }
}