import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final usernameController = TextEditingController();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final authService = AuthService();

  bool isLoading = false;
  bool isPasswordHidden = true;
  bool isConfirmPasswordHidden = true;
  bool _agreeToTerms = false;

  // Focus nodes
  final _usernameFocus = FocusNode();
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _usernameFocus.addListener(() => setState(() {}));
    _nameFocus.addListener(() => setState(() {}));
    _emailFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
    _confirmPasswordFocus.addListener(() => setState(() {}));
  }

  Future<void> register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Konfirmasi password tidak sesuai"),
        ),
      );
      return;
    }

    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Anda harus menyetujui Kebijakan Privasi & Syarat Penggunaan"),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await authService.register(
        username: usernameController.text.trim(),
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
        role: 2,
      );

      if (response["success"] == true) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Register berhasil")),
        );

        Navigator.pop(context);
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response["message"])),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  @override
  void dispose() {
    usernameController.dispose();
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    _usernameFocus.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
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
                    'Hallo! Ayo Jadi Bagian dari Narasi Lokal',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: darkText,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    'Daftar sekarang untuk mengoleksi stempel digital dan mendukung ekonomi UMKM.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: subtitleColor,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Username field
                  _buildUnderlineField(
                    controller: usernameController,
                    focusNode: _usernameFocus,
                    hintText: 'Username',
                    suffixIcon: Icon(
                      Icons.person_outline,
                      color: _usernameFocus.hasFocus
                          ? tealColor
                          : inputHintColor,
                      size: 22,
                    ),
                    darkText: darkText,
                    inputHintColor: inputHintColor,
                    underlineColor: underlineColor,
                    activeUnderlineColor: activeUnderlineColor,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Username wajib diisi";
                      }
                      if (value.length < 4) {
                        return "Username minimal 4 karakter";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Nama Lengkap field
                  _buildUnderlineField(
                    controller: nameController,
                    focusNode: _nameFocus,
                    hintText: 'Nama Lengkap',
                    darkText: darkText,
                    inputHintColor: inputHintColor,
                    underlineColor: underlineColor,
                    activeUnderlineColor: activeUnderlineColor,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Nama wajib diisi";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Email field
                  _buildUnderlineField(
                    controller: emailController,
                    focusNode: _emailFocus,
                    hintText: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    darkText: darkText,
                    inputHintColor: inputHintColor,
                    underlineColor: underlineColor,
                    activeUnderlineColor: activeUnderlineColor,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Email wajib diisi";
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return "Format email tidak valid";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Password field
                  _buildUnderlineField(
                    controller: passwordController,
                    focusNode: _passwordFocus,
                    hintText: 'Password',
                    obscureText: isPasswordHidden,
                    suffixIcon: GestureDetector(
                      onTap: () {
                        setState(() {
                          isPasswordHidden = !isPasswordHidden;
                        });
                      },
                      child: Icon(
                        isPasswordHidden
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: _passwordFocus.hasFocus
                            ? tealColor
                            : inputHintColor,
                        size: 22,
                      ),
                    ),
                    darkText: darkText,
                    inputHintColor: inputHintColor,
                    underlineColor: underlineColor,
                    activeUnderlineColor: activeUnderlineColor,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Password wajib diisi";
                      }
                      if (value.length < 6) {
                        return "Password minimal 6 karakter";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Konfirmasi Password field
                  _buildUnderlineField(
                    controller: confirmPasswordController,
                    focusNode: _confirmPasswordFocus,
                    hintText: 'Konfirmasi Password',
                    obscureText: isConfirmPasswordHidden,
                    suffixIcon: GestureDetector(
                      onTap: () {
                        setState(() {
                          isConfirmPasswordHidden = !isConfirmPasswordHidden;
                        });
                      },
                      child: Icon(
                        isConfirmPasswordHidden
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: _confirmPasswordFocus.hasFocus
                            ? tealColor
                            : inputHintColor,
                        size: 22,
                      ),
                    ),
                    darkText: darkText,
                    inputHintColor: inputHintColor,
                    underlineColor: underlineColor,
                    activeUnderlineColor: activeUnderlineColor,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Konfirmasi password wajib diisi";
                      }
                      if (value != passwordController.text) {
                        return "Password tidak sama";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Checkbox agreement
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _agreeToTerms = !_agreeToTerms;
                          });
                        },
                        child: Container(
                          width: 24,
                          height: 24,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            color: _agreeToTerms ? tealColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _agreeToTerms ? tealColor : underlineColor,
                              width: 2,
                            ),
                          ),
                          child: _agreeToTerms
                              ? const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            text: 'Dengan mendaftar, Anda menyetujui ',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: subtitleColor,
                              height: 1.5,
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
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Register button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: (isLoading || !_agreeToTerms) ? null : register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: limeGreen,
                        disabledBackgroundColor: _agreeToTerms
                            ? limeGreen.withValues(alpha: 0.5)
                            : const Color(0xFFD1D5DB),
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
                              'Daftar',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _agreeToTerms ? darkText : subtitleColor,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Login link
                  Center(
                    child: RichText(
                      text: TextSpan(
                        text: 'Sudah punya akun? ',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: subtitleColor,
                        ),
                        children: [
                          TextSpan(
                            text: 'Masuk disini',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: tealColor,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.pop(context);
                              },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Helper method for building consistent underline-style text form fields
  Widget _buildUnderlineField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required Color darkText,
    required Color inputHintColor,
    required Color underlineColor,
    required Color activeUnderlineColor,
    Widget? suffixIcon,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(
        fontSize: 15,
        color: darkText,
      ),
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.poppins(
          fontSize: 15,
          color: inputHintColor,
        ),
        suffixIcon: suffixIcon,
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
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(
            color: Colors.redAccent,
            width: 1,
          ),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(
            color: Colors.redAccent,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}