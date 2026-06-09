class RouteDetailModel {
  final String id;
  final int merchantId;
  final int thematicRouteId;
  final String namaBisnis;
  final num latitude;
  final num longitude;
  final String judulRute;
  
  // Tambahkan variabel ini untuk menyimpan jarak (default 0.0)
  double distanceToUser = 0.0; 

  RouteDetailModel({
    required this.id,
    required this.merchantId,
    required this.thematicRouteId,
    required this.namaBisnis,
    required this.latitude,
    required this.longitude,
    required this.judulRute,
  });

  factory RouteDetailModel.fromJson(Map<String, dynamic> json) {
    return RouteDetailModel(
      id: json['id'].toString(),
      merchantId: json['merchant_id'] as int,
      thematicRouteId: json['thematic_route_id'] as int,
      namaBisnis: json['nama_bisnis'] as String,
      latitude: json['latitude'] as num,
      longitude: json['longitude'] as num,
      judulRute: json['judul_rute'] as String,
    );
  }
}