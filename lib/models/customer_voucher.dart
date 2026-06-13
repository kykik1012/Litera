class CustomerVoucherModel {
  final String id;
  final String customerId; // <--- Pastikan ini ada
  final String merchantId; // <--- Pastikan ini ada (Ini yang bikin error)
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
    required this.customerId,
    required this.merchantId,
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
      customerId: json['customer_id']?.toString() ?? '',
      merchantId: json['merchant_id']?.toString() ?? '', // <--- Tangkap data merchantId
      voucherCode: json['voucher_code']?.toString() ?? '-',
      status: json['status']?.toString() ?? 'UNKNOWN',
      claimedAt: json['claimed_at'] != null ? DateTime.tryParse(json['claimed_at'].toString()) : null,
      usedAt: json['used_at'] != null ? DateTime.tryParse(json['used_at'].toString()) : null,
      customerName: json['customer_name']?.toString() ?? 'Customer',
      tipePromo: json['tipe_promo']?.toString() ?? 'PROMO',
      diskon: json['diskon'] ?? 0,
      tanggalBerlaku: json['tanggal_berlaku'] != null ? DateTime.tryParse(json['tanggal_berlaku'].toString()) : null,
      tanggalExpired: json['tanggal_expired'] != null ? DateTime.tryParse(json['tanggal_expired'].toString()) : null,
      namaProduk: json['nama_produk']?.toString() ?? 'Produk',
      namaBisnis: json['nama_bisnis']?.toString() ?? 'Toko',
    );
  }
}