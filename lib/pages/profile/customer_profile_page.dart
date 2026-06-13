import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../helpers/shared_pref_helper.dart';
import '../../services/user_service.dart';
import '../auth/login_page.dart';
import 'customer_edit_profile_page.dart';
import 'package:litera/pages/customer/customer_my_reviews_page.dart';
import '../../widgets/logout_bottom_sheet.dart';
import '../../helpers/secure_storage_helper.dart';
import '../../services/biometric_service.dart';
import '../../services/auth_service.dart';
import 'change_password_page.dart';
import '../../constants/api.dart';
import 'package:litera/pages/customer/customer_my_promo_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String username = "";
  String email = "";
  String? profilePicture;
  bool biometricEnabled = false;

  final userService = UserService();

  @override
  void initState() {
    super.initState();
    _loadUser();
    loadBiometricStatus();
  }

  Future<void> loadBiometricStatus() async {
    biometricEnabled = await SecureStorageHelper.isBiometricEnabled();
    if (mounted) setState(() {});
  }

  Future<void> toggleBiometric(bool value) async {
    final userId = await SharedPrefHelper.getUserId();
    if (value) {
      final available = await BiometricService().isAvailable();
      if (!available) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Perangkat tidak mendukung biometrik")));
        return;
      }
      final success = await BiometricService().authenticate();
      if (!success) return;

      final role = await SharedPrefHelper.getRole();
      final token = await SharedPrefHelper.getToken();
      final usernameStr = await SharedPrefHelper.getUsername();
      final emailStr = await SharedPrefHelper.getEmail();

      await AuthService().updateBiometricStatus(userId: userId ?? 0, biometricEnabled: true);
      await SecureStorageHelper.saveBiometricEnabled(enabled: true, userId: userId ?? 0, role: role ?? 2);
      await SecureStorageHelper.saveBiometricUserData(token: token ?? "", userId: userId ?? 0, username: usernameStr ?? "", email: emailStr ?? "", role: role ?? 2);
    } else {
      await AuthService().updateBiometricStatus(userId: userId ?? 0, biometricEnabled: false);
      await SecureStorageHelper.removeBiometric();
    }
    if (mounted) setState(() { biometricEnabled = value; });
  }

  Future<void> _loadUser() async {
    username = await SharedPrefHelper.getUsername() ?? "";
    email = await SharedPrefHelper.getEmail() ?? "";

    // Try to load profile picture from API
    final userId = await SharedPrefHelper.getUserId() ?? 0;
    if (userId != 0) {
      try {
        final response = await userService.getUserById(userId);
        if (response["success"] == true) {
          profilePicture = response["data"]["profile_picture"];
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

  void _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfilePage()),
    );
    // Refresh data if profile was updated
    if (result == true) {
      _loadUser();
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color bgColor = Color(0xFFF8F9FA);
    const Color tealDark = Color(0xFF145C54);
    const Color tealColor = Color(0xFF1A7A6D);
    const Color limeGreen = Color(0xFFB8E926);
    const Color darkText = Color(0xFF1A1A2E);
    const Color subtitleColor = Color(0xFF6B7280);
    const Color dividerColor = Color(0xFFE5E7EB);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Profile Card ──
              GestureDetector(
                onTap: _navigateToEditProfile,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF145C54), Color(0xFF1A8A7A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: tealDark.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Top row: avatar + name + edit icon
                        Row(
                          children: [
                            // Avatar
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.2),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                              ),
                              child: profilePicture != null && profilePicture!.isNotEmpty
                                  ? ClipOval(
                                      child: Image.network(
                                        Api.getImageUrl(profilePicture),
                                        fit: BoxFit.cover,
                                        width: 56,
                                        height: 56,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                          Icons.person,
                                          color: Colors.white70,
                                          size: 30,
                                        ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person,
                                      color: Colors.white70,
                                      size: 30,
                                    ),
                            ),
                            const SizedBox(width: 14),
                            // Name & subtitle
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    username.isEmpty ? '-' : username,
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Penjelajah Budaya',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Edit icon
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.edit_outlined,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Stats row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _StatBadge(
                              icon: Icons.confirmation_number_outlined,
                              value: '0',
                              label: 'Voucher',
                              color: limeGreen,
                            ),
                            _StatBadge(
                              icon: Icons.share_location_rounded,
                              value: '0',
                              label: 'Lokasi Dikunjungi',
                              color: limeGreen,
                            ),
                            _StatBadge(
                              icon: Icons.rate_review_outlined,
                              value: '0',
                              label: 'Ulasan',
                              color: limeGreen,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── Kegiatan section ──
              Text(
                'Kegiatan',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 12),
              
              _buildActionCard(
                icon: Icons.confirmation_number_outlined,
                iconColor: Colors.grey[700]!,
                title: 'Voucher',
                subtitle: 'Voucher yang Kamu Punya',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CustomerMyPromoPage()),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildActionCard(
                icon: Icons.rate_review_outlined,
                iconColor: Colors.grey[700]!,
                title: 'Ulasan Saya',
                subtitle: 'Ulasan yang Pernah Kamu Berikan',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CustomerMyReviewsPage()),
                  );
                },
              ),

              const SizedBox(height: 24),

              // ── Akun & Aplikasi section ──
              Text(
                'Akun & Aplikasi',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 12),
              _buildActionCard(
                icon: Icons.shield_outlined,
                iconColor: Colors.grey[700]!,
                title: 'Keamanan Akun',
                subtitle: 'Password & Akun',
                onTap: _navigateToEditProfile,
              ),
              const SizedBox(height: 12),
              _buildActionCard(
                icon: Icons.fingerprint,
                iconColor: Colors.grey[700]!,
                title: 'Sidik Jari',
                subtitle: 'Pengaturan Sidik Jari',
                trailingWidget: Switch(
                  value: biometricEnabled,
                  onChanged: toggleBiometric,
                  activeColor: tealColor,
                ),
                onTap: () {
                  toggleBiometric(!biometricEnabled);
                },
              ),
              const SizedBox(height: 12),
              _buildActionCard(
                icon: Icons.logout_rounded,
                iconColor: Colors.red,
                title: 'Keluar',
                titleColor: Colors.red,
                subtitle: 'Sampai jumpa lagi!',
                subtitleColor: Colors.red[300],
                backgroundColor: const Color(0xFFFFF0F0),
                onTap: _showLogoutDialog,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showLogoutBottomSheet(context, _logout);
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
    Widget? trailingWidget,
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
            trailingWidget ?? Icon(Icons.chevron_right, color: titleColor ?? Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

// ─── Stat Badge (inside the profile card) ───
class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatBadge({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: const Color(0xFF1A1A2E)),
              const SizedBox(width: 6),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w400,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

