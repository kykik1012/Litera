import 'package:flutter/material.dart';

import '../../helpers/shared_pref_helper.dart';
import '../profile/profile_page.dart';

class CustomerDashboardPage
    extends StatefulWidget {

  const CustomerDashboardPage({
    super.key,
  });

  @override
  State<CustomerDashboardPage>
      createState() =>
          _CustomerDashboardPageState();
}

class _CustomerDashboardPageState
    extends State<CustomerDashboardPage> {

  int currentIndex = 0;

  String username = "";
  String email = "";

  @override
  void initState() {

    super.initState();

    loadUser();
  }

  Future<void> loadUser()
  async {

    username =
        await SharedPrefHelper
            .getUsername() ??
            "";

    email =
        await SharedPrefHelper
            .getEmail() ??
            "";

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {

    final pages = [

      const Center(
        child: Text(
          "Beranda Customer",
        ),
      ),

      ProfilePage(
        name: username,
        email: email,
      ),
    ];

    return Scaffold(

      appBar: AppBar(

        title: Text(

          currentIndex == 0
              ? "Dashboard"
              : "Profile",
        ),
      ),

      body: pages[currentIndex],

      bottomNavigationBar:
          BottomNavigationBar(

        currentIndex:
            currentIndex,

        onTap: (index) {

          setState(() {

            currentIndex = index;
          });
        },

        items: const [

          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}