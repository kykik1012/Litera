import 'package:flutter/material.dart';

import '../../helpers/shared_pref_helper.dart';
import '../auth/login_page.dart';
import '../profile/edit_profile_page.dart';


class ProfilePage extends StatelessWidget {

  final String name;
  final String email;
  final String? profilePicture;

  const ProfilePage({
    super.key,
    required this.name,
    required this.email,
    this.profilePicture,
  });

  Future<void> logout(
    BuildContext context,
  ) async {

    await SharedPrefHelper.logout();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(

      context,

      MaterialPageRoute(
        builder: (_) =>
            const LoginPage(),
      ),

      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {

    return SingleChildScrollView(

      padding:
          const EdgeInsets.all(20),

      child: Column(

        children: [

          CircleAvatar(

            radius: 50,

            backgroundImage:
                profilePicture != null

                ? NetworkImage(
                    profilePicture!,
                  )

                : null,

            child:
                profilePicture == null

                ? const Icon(
                    Icons.person,
                    size: 50,
                  )

                : null,
          ),

          const SizedBox(height: 16),

          Text(

            name.isEmpty
                ? "-"
                : name,

            style:
                const TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            email.isEmpty
                ? "-"
                : email,
          ),

          const SizedBox(height: 30),

          Card(

            child: ListTile(

              leading:
                  const Icon(
                Icons.person,
              ),

              title:
                  const Text(
                "Edit Profile",
              ),

              trailing:
                  const Icon(
                Icons.arrow_forward_ios,
                size: 18,
              ),

              onTap: () {

                Navigator.push(

                  context,

                  MaterialPageRoute(

                    builder: (_) =>
                        const EditProfilePage(),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          Card(

            child: ListTile(

              leading:
                  const Icon(
                Icons.lock,
              ),

              title:
                  const Text(
                "Ganti Password",
              ),

              trailing:
                  const Icon(
                Icons.arrow_forward_ios,
                size: 18,
              ),

              onTap: () {

                Navigator.push(

                  context,

                  MaterialPageRoute(

                    builder: (_) =>
                        const EditProfilePage(),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          Card(

            child: ListTile(

              leading:
                  const Icon(
                Icons.logout,
                color: Colors.red,
              ),

              title:
                  const Text(
                "Logout",
                style: TextStyle(
                  color: Colors.red,
                ),
              ),

              trailing:
                  const Icon(
                Icons.arrow_forward_ios,
                size: 18,
              ),

              onTap: () {

                logout(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}