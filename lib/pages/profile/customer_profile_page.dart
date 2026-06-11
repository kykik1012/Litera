import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../helpers/shared_pref_helper.dart';
import '../../services/user_service.dart';
import '../auth/login_page.dart';
import 'customer_edit_profile_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String username = "";
  String email = "";
  String? profilePicture;
  bool _notificationsEnabled = true;

  final userService = UserService();

  @override
  void initState() {
    super.initState();
    _loadUser();
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
    const Color bgColor = Color.fromARGB(255, 255, 255, 255);
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
                              child: profilePicture != null
                                  ? ClipOval(
                                      child: Image.network(
                                        profilePicture!,
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
                              icon: Icons.alt_route_rounded,
                              value: '2',
                              label: 'Rute Dikunjungi',
                              color: limeGreen,
                            ),
                            _StatBadge(
                              icon: Icons.share_location_rounded,
                              value: '12',
                              label: 'Lokasi Dikunjungi',
                              color: limeGreen,
                            ),
                            _StatBadge(
                              icon: Icons.rate_review_outlined,
                              value: '3',
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

              // ── Lainnya section ──
              Text(
                'Lainnya',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 12),

              // Menu items
              _MenuItem(
                icon: Icons.confirmation_number_outlined,
                label: 'Voucher',
                textColor: darkText,
                subtitleColor: subtitleColor,
                dividerColor: dividerColor,
                onTap: () {
                  // TODO: Navigate to voucher page
                },
              ),

              // Notifikasi with toggle
              _MenuToggleItem(
                icon: Icons.notifications_none_rounded,
                label: 'Notifikasi',
                textColor: darkText,
                subtitleColor: subtitleColor,
                dividerColor: dividerColor,
                tealColor: tealColor,
                limeGreen: limeGreen,
                value: _notificationsEnabled,
                onChanged: (val) {
                  setState(() {
                    _notificationsEnabled = val;
                  });
                },
              ),

              _MenuItem(
                icon: Icons.help_outline_rounded,
                label: 'Pusat Bantuan',
                textColor: darkText,
                subtitleColor: subtitleColor,
                dividerColor: dividerColor,
                onTap: () {
                  // TODO: Navigate to help center
                },
              ),

              _MenuItem(
                icon: Icons.logout_rounded,
                label: 'Keluar',
                textColor: darkText,
                subtitleColor: subtitleColor,
                dividerColor: dividerColor,
                showDivider: false,
                onTap: () {
                  _showLogoutDialog();
                },
              ),
            ],
          ),
        ),
      ),
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

// ─── Menu Item ───
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color textColor;
  final Color subtitleColor;
  final Color dividerColor;
  final VoidCallback onTap;
  final bool showDivider;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.textColor,
    required this.subtitleColor,
    required this.dividerColor,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 24, color: subtitleColor),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: textColor,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: subtitleColor,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(height: 1, color: dividerColor),
      ],
    );
  }
}

// ─── Menu Toggle Item (for Notifikasi) ───
class _MenuToggleItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color textColor;
  final Color subtitleColor;
  final Color dividerColor;
  final Color tealColor;
  final Color limeGreen;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _MenuToggleItem({
    required this.icon,
    required this.label,
    required this.textColor,
    required this.subtitleColor,
    required this.dividerColor,
    required this.tealColor,
    required this.limeGreen,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 24, color: subtitleColor),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: textColor,
                  ),
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: Colors.white,
                activeTrackColor: limeGreen,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: const Color(0xFFD1D5DB),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
        Divider(height: 1, color: dividerColor),
      ],
    );
  }
}