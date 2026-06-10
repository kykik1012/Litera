import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Import service dan model rute
import 'package:litera/services/thematic_service.dart';
import 'package:litera/models/thematic_route.dart';

// Sesuaikan path map_navigation_page.dart jika diperlukan
import '../MAPS/map_navigation_page.dart';  

// Cukup gunakan StatelessWidget karena tidak ada state lokal (navbar) yang perlu diubah di sini
class AdminDashboardPage extends StatelessWidget {
  AdminDashboardPage({super.key});

  final ThematicRouteService _routeService = ThematicRouteService();

  static const Color tealDark = Color(0xFF145C54);
  static const Color limeGreen = Color(0xFFB8E926);

  // Fungsi khusus untuk membangun UI Beranda Admin (Daftar Rute)
  Widget _buildHomeContent() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _routeService.getAllThematicRoutes(),
      builder: (context, snapshot) {
        // 1. Tampilkan loading saat mengambil data
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: tealDark));
        }
        
        // 2. Tangani jika terjadi error koneksi
        if (snapshot.hasError) {
          return Center(child: Text('Terjadi kesalahan: ${snapshot.error}', style: GoogleFonts.poppins()));
        }

        final response = snapshot.data;
        
        // 3. Pastikan API sukses dan ada datanya
        if (response != null && response['success'] == true) {
          List<dynamic> data = response['data'];
          
          // Mapping data JSON menjadi List<ThematicRouteModel>
          List<ThematicRouteModel> routes = data
              .map((json) => ThematicRouteModel.fromJson(json))
              .toList();

          if (routes.isEmpty) {
            return Center(child: Text('Belum ada rute tematik.', style: GoogleFonts.poppins(color: Colors.grey)));
          }

          // 4. Buat List View berupa Card
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: routes.length,
            itemBuilder: (context, index) {
              final route = routes[index];
              return Card(
                elevation: 0,
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route.judulRute,
                        style: GoogleFonts.poppins(
                          fontSize: 16, 
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        route.deskripsi,
                        style: GoogleFonts.poppins(color: Colors.grey[700], fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MapNavigationPage(
                                  thematicRouteId: int.parse(route.id),
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.play_arrow_rounded, size: 20),
                          label: Text("Mulai", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: limeGreen,
                            foregroundColor: tealDark,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }

        return Center(child: Text('Gagal memuat data rute.', style: GoogleFonts.poppins()));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          "Admin Dashboard",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A1A2E),
          ),
        ),
      ),
      body: _buildHomeContent(),
    );
  }
}