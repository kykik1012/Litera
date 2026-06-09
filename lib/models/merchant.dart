class MerchantModel {
  final String id;
  final String userId;
  final String namaBisnis;
  final int? tahunBerdiri;
  final String? deskripsi;
  final String? profilePicture;
  final num? latitude;
  final num? longitude;

  MerchantModel({
    required this.id,
    required this.userId,
    required this.namaBisnis,
    this.tahunBerdiri,
    this.deskripsi,
    this.profilePicture,
    this.latitude,
    this.longitude,
  });

  factory MerchantModel.fromJson(Map<String, dynamic> json) {
    return MerchantModel(
      // Gunakan .toString() agar selalu aman jika API merespon int atau String
      id: json['id'].toString(), 
      userId: json['user_id'].toString(),
      namaBisnis: json['nama_bisnis'] as String,
      
      // Gunakan int.tryParse() untuk berjaga-jaga jika API mengirim angka dalam bentuk String
      tahunBerdiri: json['tahun_berdiri'] != null 
          ? int.tryParse(json['tahun_berdiri'].toString()) 
          : null,
          
      deskripsi: json['deskripsi'] as String?,
      profilePicture: json['profile_picture'] as String?,
      
      // Gunakan num untuk menerima baik int maupun double dari JSON
      latitude: json['latitude'] as num?,
      longitude: json['longitude'] as num?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'nama_bisnis': namaBisnis,
      'tahun_berdiri': tahunBerdiri,
      'deskripsi': deskripsi,
      'profile_picture': profilePicture,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}