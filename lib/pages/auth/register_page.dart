import 'package:flutter/material.dart';

import '../../services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() =>
      _RegisterPageState();
}

class _RegisterPageState
    extends State<RegisterPage> {

  final _formKey =
      GlobalKey<FormState>();

  final usernameController =
      TextEditingController();

  final nameController =
      TextEditingController();

  final emailController =
      TextEditingController();

  final passwordController =
      TextEditingController();

  final confirmPasswordController =
      TextEditingController();

  final authService =
      AuthService();

  bool isLoading = false;

  bool isPasswordHidden = true;

  bool isConfirmPasswordHidden =
      true;

  Future<void> register() async {

    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    if (passwordController.text !=
        confirmPasswordController.text) {

      ScaffoldMessenger.of(context)
          .showSnackBar(

        const SnackBar(
          content: Text(
            "Konfirmasi password tidak sesuai",
          ),
        ),
      );

      return;
    }

    setState(() {
      isLoading = true;
    });

    try {

      final response =
          await authService.register(

        username:
            usernameController.text
                .trim(),

        name:
            nameController.text.trim(),

        email:
            emailController.text.trim(),

        password:
            passwordController.text,

        role: 2,
      );

      if (response["success"] ==
          true) {

        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(

          const SnackBar(
            content: Text(
              "Register berhasil",
            ),
          ),
        );

        Navigator.pop(context);

      } else {

        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(

          SnackBar(
            content: Text(
              response["message"],
            ),
          ),
        );
      }

    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(

        SnackBar(
          content: Text(
            e.toString(),
          ),
        ),
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

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text(
          "Register Customer",
        ),
      ),

      body: SingleChildScrollView(

        padding:
            const EdgeInsets.all(20),

        child: Form(

          key: _formKey,

          child: Column(

            children: [

              TextFormField(

                controller:
                    usernameController,

                validator: (value) {

                  if (value == null ||
                      value.trim()
                          .isEmpty) {

                    return "Username wajib diisi";
                  }

                  if (value.length < 4) {

                    return "Username minimal 4 karakter";
                  }

                  return null;
                },

                decoration:
                    const InputDecoration(
                  labelText: "Username",
                  border:
                      OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(

                controller:
                    nameController,

                validator: (value) {

                  if (value == null ||
                      value.trim()
                          .isEmpty) {

                    return "Nama wajib diisi";
                  }

                  return null;
                },

                decoration:
                    const InputDecoration(
                  labelText: "Nama",
                  border:
                      OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(

                controller:
                    emailController,

                keyboardType:
                    TextInputType
                        .emailAddress,

                validator: (value) {

                  if (value == null ||
                      value.trim()
                          .isEmpty) {

                    return "Email wajib diisi";
                  }

                  if (!RegExp(
                    r'^[^@]+@[^@]+\.[^@]+',
                  ).hasMatch(value)) {

                    return "Format email tidak valid";
                  }

                  return null;
                },

                decoration:
                    const InputDecoration(
                  labelText: "Email",
                  border:
                      OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(

                controller:
                    passwordController,

                obscureText:
                    isPasswordHidden,

                validator: (value) {

                  if (value == null ||
                      value.isEmpty) {

                    return "Password wajib diisi";
                  }

                  if (value.length < 6) {

                    return "Password minimal 6 karakter";
                  }

                  return null;
                },

                decoration:
                    InputDecoration(

                  labelText:
                      "Password",

                  border:
                      const OutlineInputBorder(),

                  suffixIcon:
                      IconButton(

                    onPressed: () {

                      setState(() {

                        isPasswordHidden =
                            !isPasswordHidden;
                      });
                    },

                    icon: Icon(

                      isPasswordHidden
                          ? Icons
                              .visibility
                          : Icons
                              .visibility_off,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(

                controller:
                    confirmPasswordController,

                obscureText:
                    isConfirmPasswordHidden,

                validator: (value) {

                  if (value == null ||
                      value.isEmpty) {

                    return "Konfirmasi password wajib diisi";
                  }

                  if (value !=
                      passwordController
                          .text) {

                    return "Password tidak sama";
                  }

                  return null;
                },

                decoration:
                    InputDecoration(

                  labelText:
                      "Konfirmasi Password",

                  border:
                      const OutlineInputBorder(),

                  suffixIcon:
                      IconButton(

                    onPressed: () {

                      setState(() {

                        isConfirmPasswordHidden =
                            !isConfirmPasswordHidden;
                      });
                    },

                    icon: Icon(

                      isConfirmPasswordHidden
                          ? Icons
                              .visibility
                          : Icons
                              .visibility_off,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(

                width:
                    double.infinity,

                height: 50,

                child:
                    ElevatedButton(

                  onPressed:
                      isLoading
                          ? null
                          : register,

                  child:
                      isLoading

                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child:
                              CircularProgressIndicator(),
                        )

                      : const Text(
                          "Daftar",
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}