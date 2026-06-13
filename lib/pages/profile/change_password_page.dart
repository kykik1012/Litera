import 'package:flutter/material.dart';

import '../../helpers/shared_pref_helper.dart';
import '../../services/auth_service.dart';

class ChangePasswordPage
    extends StatefulWidget {

  const ChangePasswordPage({
    super.key,
  });

  @override
  State<ChangePasswordPage>
      createState() =>
          _ChangePasswordPageState();
}

class _ChangePasswordPageState
    extends State<ChangePasswordPage> {

  final oldPasswordController =
      TextEditingController();

  final newPasswordController =
      TextEditingController();

  bool isLoading = false;

  Future<void>
      changePassword() async {

    setState(() {
      isLoading = true;
    });

    try {

      final userId =
          await SharedPrefHelper
              .getUserId();

      final response =
          await AuthService()
              .changePassword(

        userId: userId ?? 0,

        oldPassword:
            oldPasswordController.text,

        newPassword:
            newPasswordController.text,
      );

      if (
          response["success"] ==
              true) {

        if (!mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(

          SnackBar(

            content: Text(
              response["message"],
            ),
          ),
        );

        Navigator.pop(
          context,
        );
      }

      else {

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(

          SnackBar(

            content: Text(
              response["message"],
            ),
          ),
        );
      }
    }

    catch (e) {

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(

        SnackBar(

          content: Text(
            e.toString(),
          ),
        ),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(
    BuildContext context,
  ) {

    return Scaffold(

      appBar: AppBar(
        title:
            const Text(
          "Ganti Password",
        ),
      ),

      body: Padding(

        padding:
            const EdgeInsets.all(
          20,
        ),

        child: Column(

          children: [

            TextField(

              controller:
                  oldPasswordController,

              obscureText: true,

              decoration:
                  const InputDecoration(
                labelText:
                    "Password Lama",
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            TextField(

              controller:
                  newPasswordController,

              obscureText: true,

              decoration:
                  const InputDecoration(
                labelText:
                    "Password Baru",
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            SizedBox(

              width:
                  double.infinity,

              child:
                  ElevatedButton(

                onPressed:
                    isLoading
                        ? null
                        : changePassword,

                child:
                    isLoading

                        ? const CircularProgressIndicator()

                        : const Text(
                            "Simpan",
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
