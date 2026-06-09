class UserModel {
  final String id; 
  final String email;
  final String? username;
  final String? name; 
  final int? role;
  final String? profilePicture;
  final DateTime? createdAt;
  final String? namaBisnis;
  
  // TAMBAHAN: Properti isActive untuk mendeteksi status soft delete
  final bool isActive; 

  UserModel({
    required this.id,
    required this.email,
    this.username,
    this.name,
    this.role,
    this.profilePicture,
    this.createdAt,
    this.namaBisnis,
    // Atur nilai default menjadi true jika tidak diberikan
    this.isActive = true, 
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(), 
      email: json['email'] as String,
      username: json['username'] as String?,
      name: json['name'] as String?,
      role: json['role'] as int?,
      profilePicture: json['profile_picture'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      namaBisnis: json['nama_bisnis'] as String?,
      
      // TAMBAHAN: Parsing is_active dari JSON API
      // Jika bernilai null dari server, kita asumsikan true
      isActive: json['is_active'] ?? true, 
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'name': name,
      'role': role,
      'profile_picture': profilePicture,
      'created_at': createdAt?.toIso8601String(),
      'nama_bisnis': namaBisnis,
      // TAMBAHAN: Sertakan is_active saat konversi ke JSON
      'is_active': isActive, 
    };
  }
}