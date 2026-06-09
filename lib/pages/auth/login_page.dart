import 'package:flutter/material.dart';

import '../../helpers/shared_pref_helper.dart';
import '../../services/auth_service.dart';

// Ganti import dashboard dengan import MainScreen
import 'package:litera/main_screen.dart'; // Sesuaikan path ini jika MainScreen ada di folder berbeda
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: "Username",
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : login,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text("Login"),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RegisterPage(),
                  ),
                );
              },
              child: const Text("Belum punya akun? Daftar"),
            ),
          ],
        ),
      ),
    );
  }
}