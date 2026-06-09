class CustomerVoucherModel {
  final String id;
  final String voucherCode;
  final String status;
  final DateTime? claimedAt;
  final DateTime? usedAt;
  final String customerName;
  final String tipePromo;
  final num diskon;
  final DateTime? tanggalBerlaku;
  final DateTime? tanggalExpired;
  final String namaProduk;
  final String namaBisnis;

  CustomerVoucherModel({
    required this.id,
    required this.voucherCode,
    required this.status,
    this.claimedAt,
    this.usedAt,
    required this.customerName,
    required this.tipePromo,
    required this.diskon,
    this.tanggalBerlaku,
    this.tanggalExpired,
    required this.namaProduk,
    required this.namaBisnis,
  });

  factory CustomerVoucherModel.fromJson(Map<String, dynamic> json) {
    return CustomerVoucherModel(
      id: json['id'].toString(),
      voucherCode: json['voucher_code'] as String,
      status: json['status'] as String,
      claimedAt: json['claimed_at'] != null ? DateTime.parse(json['claimed_at']) : null,
      usedAt: json['used_at'] != null ? DateTime.parse(json['used_at']) : null,
      customerName: json['customer_name'] as String,
      tipePromo: json['tipe_promo'] as String,
      diskon: json['diskon'] as num,
      tanggalBerlaku: json['tanggal_berlaku'] != null ? DateTime.parse(json['tanggal_berlaku']) : null,
      tanggalExpired: json['tanggal_expired'] != null ? DateTime.parse(json['tanggal_expired']) : null,
      namaProduk: json['nama_produk'] as String,
      namaBisnis: json['nama_bisnis'] as String,
    );
  }
}