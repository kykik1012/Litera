import 'package:flutter/material.dart';

class MerchantDashboardPage
    extends StatelessWidget {

  const MerchantDashboardPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title:
            const Text(
          "Merchant Dashboard",
        ),
      ),

      body: const Center(
        child:
            Text(
          "LOGIN MERCHANT BERHASIL",
        ),
      ),
    );
  }
}