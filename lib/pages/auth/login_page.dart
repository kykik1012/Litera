import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../helpers/shared_pref_helper.dart';
import '../../services/auth_service.dart';

import '../../main_screen.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final authService = AuthService();

  bool isLoading = false;
  bool _isPasswordHidden = true;

  // Focus nodes to track active field
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _usernameFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // LOGIN FUNCTION
  Future<void> login() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await authService.login(
        username: usernameController.text,
        password: passwordController.text,
      );

      // LOGIN BERHASIL
      if (response["success"] == true) {
        final token = response["data"]["token"];
        final user = response["data"]["user"];

        // SAVE TOKEN & USER DATA
        await SharedPrefHelper.saveUserData(
          token: token,
          id: int.parse(user["id"].toString()),
          username: user["username"].toString(),
          email: user["email"].toString(),
          role: int.parse(user["role"].toString()),
        );

        // Pastikan widget masih aktif sebelum melakukan navigasi
        if (!mounted) return;

        // Semua pengguna yang berhasil login langsung diarahkan ke MainScreen
        // MainScreen akan otomatis membaca role dan menampilkan halaman yang sesuai
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const MainScreen(),
          ),
        );
      }
      // LOGIN GAGAL
      else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response["message"]),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Colors from design
    const Color bgColor = Color.fromARGB(255, 255, 255, 255);
    const Color tealColor = Color(0xFF1A7A6D);
    const Color darkText = Color(0xFF1A1A2E);
    const Color subtitleColor = Color(0xFF6B7280);
    const Color inputHintColor = Color(0xFFA0AEC0);
    const Color underlineColor = Color(0xFFD1D5DB);
    const Color activeUnderlineColor = Color(0xFF1A7A6D);
    const Color limeGreen = Color(0xFFB8E926);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),

                        // Logo
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/images/logo_litera.png',
                                height: 36,
                              ),
                              const SizedBox(width: 8),
                              // Text(
                              //   'Litera',
                              //   style: GoogleFonts.poppins(
                              //     fontSize: 22,
                              //     fontWeight: FontWeight.w700,
                              //     color: tealColor,
                              //   ),
                              // ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 36),

                        // Heading
                        Text(
                          'Horee! Kamu Kembali',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: darkText,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Subtitle
                        Text(
                          'Masuk untuk melanjutkan perjalanan dan cek promo "Rasa Kilat" di sekitarmu.',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: subtitleColor,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 48),

                        // Username field
                        TextField(
                          controller: usernameController,
                          focusNode: _usernameFocus,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            color: darkText,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Username',
                            hintStyle: GoogleFonts.poppins(
                              fontSize: 15,
                              color: inputHintColor,
                            ),
                            suffixIcon: Icon(
                              Icons.person_outline,
                              color: _usernameFocus.hasFocus
                                  ? tealColor
                                  : inputHintColor,
                              size: 22,
                            ),
                            border: InputBorder.none,
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: underlineColor,
                                width: 1,
                              ),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: activeUnderlineColor,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Password field
                        TextField(
                          controller: passwordController,
                          focusNode: _passwordFocus,
                          obscureText: _isPasswordHidden,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            color: darkText,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Password',
                            hintStyle: GoogleFonts.poppins(
                              fontSize: 15,
                              color: inputHintColor,
                            ),
                            suffixIcon: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isPasswordHidden = !_isPasswordHidden;
                                });
                              },
                              child: Icon(
                                _isPasswordHidden
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: _passwordFocus.hasFocus
                                    ? tealColor
                                    : inputHintColor,
                                size: 22,
                              ),
                            ),
                            border: InputBorder.none,
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: underlineColor,
                                width: 1,
                              ),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: activeUnderlineColor,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Forget password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              // TODO: navigate to forget password
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Forget password?',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: tealColor,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Login button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: limeGreen,
                              disabledBackgroundColor:
                                  limeGreen.withValues(alpha: 0.5),
                              foregroundColor: darkText,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Color(0xFF1A1A2E),
                                    ),
                                  )
                                : Text(
                                    'Masuk',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: darkText,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Register link
                        Center(
                          child: RichText(
                            text: TextSpan(
                              text: 'Belum punya akun? ',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: subtitleColor,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Daftar Sekarang',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: tealColor,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const RegisterPage(),
                                        ),
                                      );
                                    },
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Spacer pushes footer to bottom
                        const Spacer(),

                        // Footer - privacy policy
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Center(
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                text: 'Dengan masuk, Anda menyetujui ',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: subtitleColor,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Kebijakan Privasi & Syarat Penggunaan',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: tealColor,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '.',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: subtitleColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}