import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../helpers/shared_pref_helper.dart';
import '../../services/user_service.dart';
import '../auth/login_page.dart';
import 'merchant_edit_profile_page.dart';

class MerchantProfilePage extends StatefulWidget {
  const MerchantProfilePage({super.key});

  @override
  State<MerchantProfilePage> createState() => _MerchantProfilePageState();
}

class _MerchantProfilePageState extends State<MerchantProfilePage> {
  static const Color tealDark = Color(0xFF0D3B2E);
  static const Color limeGreen = Color(0xFFAEEA00);

  String username = "";
  String email = "";
  String? profilePicture;
  final userService = UserService();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    username = await SharedPrefHelper.getUsername() ?? "";
    email = await SharedPrefHelper.getEmail() ?? "";

    final userId = await SharedPrefHelper.getUserId() ?? 0;
    if (userId != 0) {
      try {
        final response = await userService.getUserById(userId);
        if (response["success"] == true) {
          final data = response["data"];
          if (data["nama_bisnis"] != null && data["nama_bisnis"].toString().isNotEmpty) {
             username = data["nama_bisnis"];
          } else if (data["name"] != null && data["name"].toString().isNotEmpty) {
             username = data["name"];
          }
          profilePicture = data["profile_picture"];
        }
      } catch (_) {}
    }

    if (mounted) setState(() {});
  }

  Future<void> _logout() async {
    await SharedPrefHelper.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Keluar',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar?',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(color: const Color(0xFF6B7280)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _logout();
            },
            child: Text(
              'Keluar',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Mencegah back button sistem logout langsung
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: SafeArea(
          child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileCard(),
                const SizedBox(height: 20),
                _buildCompletenessCard(),
                const SizedBox(height: 24),
                Text(
                  'Kelola Usaha',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 12),
                _buildActionCard(
                  icon: Icons.location_on_outlined,
                  iconColor: Colors.blueAccent,
                  title: 'Lokasi Pinpoint',
                  subtitle: 'Jl. Sudirman',
                  onTap: () {},
                ),
                const SizedBox(height: 24),
                Text(
                  'Akun & Aplikasi',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 12),
                _buildActionCard(
                  icon: Icons.shield_outlined,
                  iconColor: Colors.grey[700]!,
                  title: 'Keamanan Akun',
                  subtitle: 'Password & Akun',
                  onTap: () {},
                ),
                const SizedBox(height: 12),
                _buildActionCard(
                  icon: Icons.fingerprint,
                  iconColor: Colors.grey[700]!,
                  title: 'Sidik Jari',
                  subtitle: 'Pengaturan Sidik Jari',
                  onTap: () {},
                ),
                const SizedBox(height: 12),
                _buildActionCard(
                  icon: Icons.logout,
                  iconColor: Colors.red,
                  title: 'Keluar',
                  titleColor: Colors.red,
                  subtitle: 'Sampai jumpa lagi!',
                  subtitleColor: Colors.red[300],
                  backgroundColor: const Color(0xFFFFF0F0),
                  onTap: _showLogoutDialog, // Hubungkan fungsi dialog logout
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      decoration: BoxDecoration(
        color: tealDark,
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [tealDark, Color(0xFF145C54)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: profilePicture != null
                    ? ClipOval(
                        child: Image.network(
                          profilePicture!,
                          fit: BoxFit.cover,
                          width: 60,
                          height: 60,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.storefront,
                            size: 30,
                            color: Colors.white70,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.storefront,
                        size: 30,
                        color: Colors.white70,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username.isEmpty ? 'Nama Merchant' : username,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      email.isEmpty ? 'email@merchant.com' : email,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.edit_square,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              
              // --- UBAH BAGIAN INI ---
              onPressed: () async {
                // Menunggu halaman edit ditutup
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MerchantEditProfilePage(),
                  ),
                );
                
                // Jika hasilnya true (artinya ada perubahan yang disimpan), refresh data profil
                if (result == true) {
                  _loadUser();
                }
              },
              // -----------------------
              
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: tealDark,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Edit Profil Usaha',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletenessCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kelengkapan Profil Usaha',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
              const Icon(Icons.extension, color: limeGreen, size: 28),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '65% • Bisa lebih maksimal!',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: 0.65,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(limeGreen),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 16),
          Text(
            'Lengkapi profil usahamu agar terlihat lebih profesional dan lebih mudah dipercaya pelanggan.',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFC8E6C9)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.settings, color: Color(0xFF2E7D32), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Lengkapi profil sekarang',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: Color(0xFF2E7D32), size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Color? titleColor,
    Color? subtitleColor,
    Color? backgroundColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: backgroundColor != null ? Colors.transparent : Colors.grey[200]!,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: backgroundColor != null ? Colors.white : Colors.grey[50],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: titleColor ?? const Color(0xFF1A1A2E),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: subtitleColor ?? Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: titleColor ?? Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
