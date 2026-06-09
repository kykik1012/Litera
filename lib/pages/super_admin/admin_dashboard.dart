import 'package:flutter/material.dart';

// Import service dan model rute
import 'package:litera/services/thematic_service.dart';
import 'package:litera/models/thematic_route.dart';

// Sesuaikan path map_navigation_page.dart jika diperlukan
import '../MAPS/map_navigation_page.dart';  

// Cukup gunakan StatelessWidget karena tidak ada state lokal (navbar) yang perlu diubah di sini
class AdminDashboardPage extends StatelessWidget {
  AdminDashboardPage({super.key});

  // Inisialisasi service
  final ThematicRouteService _routeService = ThematicRouteService();

  // Fungsi khusus untuk membangun UI Beranda Admin (Daftar Rute)
  Widget _buildHomeContent() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _routeService.getAllThematicRoutes(),
      builder: (context, snapshot) {
        // 1. Tampilkan loading saat mengambil data
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        // 2. Tangani jika terjadi error koneksi
        if (snapshot.hasError) {
          return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
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
            return const Center(child: Text('Belum ada rute tematik.'));
          }

          // 4. Buat List View berupa Card
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: routes.length,
            itemBuilder: (context, index) {
              final route = routes[index];
              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route.judulRute,
                        style: const TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        route.deskripsi,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Navigasi ke Map Navigation Page dan kirimkan ID
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MapNavigationPage(
                                  // Parse id dari String (di model) menjadi int (di parameter page)
                                  thematicRouteId: int.parse(route.id),
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.play_arrow),
                          label: const Text("Mulai"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
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

        // Tampilan default jika struktur response tidak sesuai
        return const Center(child: Text('Gagal memuat data rute.'));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
      ),
      // Langsung panggil FutureBuilder di dalam body
      body: _buildHomeContent(),
    );
  }
}