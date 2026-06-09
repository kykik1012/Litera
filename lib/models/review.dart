class ReviewModel {
  final String id;
  final int rating;
  final String deskripsi;
  final String? imageUrl;
  final DateTime? submittedAt;
  final String customerName;
  final String namaBisnis;

  ReviewModel({
    required this.id,
    required this.rating,
    required this.deskripsi,
    this.imageUrl,
    this.submittedAt,
    required this.customerName,
    required this.namaBisnis,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'].toString(),
      rating: json['rating'] as int,
      deskripsi: json['deskripsi'] as String,
      imageUrl: json['image_url'] as String?,
      submittedAt: json['submitted_at'] != null ? DateTime.parse(json['submitted_at']) : null,
      customerName: json['customer_name'] as String,
      namaBisnis: json['nama_bisnis'] as String,
    );
  }
}