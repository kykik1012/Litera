import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {

    final pages = [

      const Center(
        child: Text(
          "Beranda Customer",
        ),
      ),

      const ProfilePage(),
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