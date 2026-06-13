import 'package:flutter/material.dart';
import 'helpers/shared_pref_helper.dart';

// Import halaman dashboard
import 'package:litera/pages/super_admin/admin_dashboard.dart';
import 'package:litera/pages/super_admin/kelola_akun.dart';
import 'package:litera/pages/super_admin/kelola_rute.dart';
import 'package:litera/pages/super_admin/kelola_review.dart';
import 'package:litera/pages/merchant/merchant_dashboard_page.dart';
import 'package:litera/pages/merchant/merchant_usaha_page.dart';
import 'package:litera/pages/merchant/merchant_ulasan_page.dart';
import 'package:litera/pages/merchant/merchant_kelola_promo.dart';
import 'package:litera/pages/customer/customer_promo_page.dart';
import 'package:litera/pages/customer/customer_dashboard_page.dart';
import 'package:litera/pages/customer/customer_jelajah_page.dart';
import 'package:litera/pages/customer/customer_scanner.dart'; // Pastikan file ini ada di folder lib/pages/customer/
import 'package:litera/pages/profile/customer_profile_page.dart';
import 'package:litera/pages/profile/merchant_profile_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  int? _userRole;
  bool _isLoading = true;

  // Warna Utama (Disesuaikan dengan gambar)
  final Color darkGreen = const Color(0xFF003D33); // Hijau tua untuk teks/icon aktif
  final Color limeGreen = const Color(0xFFAEEA00); // Hijau stabilo untuk customer

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final role = await SharedPrefHelper.getRole();

    setState(() {
      _userRole = role;
      _isLoading = false;
    });
  }

  // --- 1. DAFTAR HALAMAN ---
  List<Widget> _getPages() {
    if (_userRole == 3) { // SUPER ADMIN
      return [
        AdminDashboardPage(),
        KelolaAkunPage(),
        KelolaReviewPage(), // Tombol Tengah
        KelolaRutePage(),
        const ProfilePage(),
      ];
    } else if (_userRole == 1) { // MERCHANT
      return [
        const MerchantDashboardPage(),
        const MerchantUsahaPage(),
        // Menu tengah Merchant diganti menjadi Promo
        const MerchantKelolaPromoPage(), 
        const MerchantUlasanPage(),
        const MerchantProfilePage(),
      ];
    } else { // CUSTOMER / USER (Role = 2)
      return [
        const CustomerDashboardPage(),
        const CustomerJelajahPage(),
        // Menu tengah Customer diisi dengan Scanner QR
        const CustomerScannerPage(), 
        const CustomerPromoPage(),
        const ProfilePage(),
      ];
    }
  }

  // --- 2. WIDGET NAVBAR KUSTOM ---
  Widget _buildCustomNavBar() {
    return Container(
      height: 95, // Tinggi total untuk menampung tombol yang melayang
      color: Colors.transparent,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Background Putih Melengkung
          Container(
            height: 70, // Tinggi dasar navbar
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
          ),
          
          // Deretan Ikon Navbar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: _userRole == 3
                ? _buildAdminNavItems()
                : _userRole == 1
                    ? _buildMerchantNavItems()
                    : _buildCustomerNavItems(),
          ),
        ],
      ),
    );
  }

  // --- 3. KOMPONEN ITEM BIASA & ITEM TENGAH ---
  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 70,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? darkGreen : Colors.grey[400],
                size: 26,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? darkGreen : Colors.grey[400],
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterNavItem(int index, IconData icon, String label, Color bgColor, Color iconColor) {
    bool isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 95, // Dibuat lebih tinggi agar lingkaran bisa "keluar"
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4), // Border putih pembatas
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? darkGreen : Colors.grey[400],
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const SizedBox(height: 8), // Jarak bawah
            ],
          ),
        ),
      ),
    );
  }

  // --- 4. ITEM NAVBAR PER ROLE ---
  List<Widget> _buildAdminNavItems() {
    return [
      _buildNavItem(0, Icons.home_rounded, "Beranda"),
      _buildNavItem(1, Icons.manage_accounts_outlined, "Akun"),
      // Admin diberi warna hijau tua untuk tombol tengah
      _buildCenterNavItem(2, Icons.rate_review_rounded, "Review", darkGreen, Colors.white),
      _buildNavItem(3, Icons.alt_route_rounded, "Rute"),
      _buildNavItem(4, Icons.person_outline_rounded, "Profil"),
    ];
  }

  List<Widget> _buildMerchantNavItems() {
    return [
      _buildNavItem(0, Icons.home_rounded, "Beranda"),
      _buildNavItem(1, Icons.storefront_outlined, "Usaha"),
      // Merchant: Background Hijau Tua, Ikon Putih
      _buildCenterNavItem(2, Icons.local_offer_outlined, "Promo", darkGreen, Colors.white),
      _buildNavItem(3, Icons.star_border_rounded, "Ulasan"),
      _buildNavItem(4, Icons.person_outline_rounded, "Profil"),
    ];
  }

  List<Widget> _buildCustomerNavItems() {
    return [
      _buildNavItem(0, Icons.home_rounded, "Beranda"),
      _buildNavItem(1, Icons.explore_outlined, "Jelajah"),
      // Customer: Background Hijau Stabilo, Ikon Hijau Tua
      _buildCenterNavItem(2, Icons.qr_code_scanner_rounded, "Pindai", limeGreen, darkGreen),
      _buildNavItem(3, Icons.local_offer_outlined, "Promo"),
      _buildNavItem(4, Icons.person_outline_rounded, "Profil"),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final pages = _getPages();
    if (_currentIndex >= pages.length) {
      _currentIndex = 0; // Proteksi jika pindah role
    }

    return Scaffold(
      extendBody: true, // PENTING: Agar body berada di bawah area transparan navbar
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: _buildCustomNavBar(),
    );
  }
}