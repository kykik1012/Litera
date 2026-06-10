import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../../pages/customer/customer_result_page.dart'; // Sesuaikan jika nama filenya search_results_page.dart
import '../../helpers/shared_pref_helper.dart';
import 'package:litera/models/merchant.dart';
import 'package:litera/models/thematic_route.dart';
import '../../services/merchant_service.dart';
import '../../services/thematic_service.dart';

class CustomerDashboardPage extends StatefulWidget {
  const CustomerDashboardPage({super.key});

  @override
  State<CustomerDashboardPage> createState() => _CustomerDashboardPageState();
}

class _CustomerDashboardPageState extends State<CustomerDashboardPage> {
  final MapController _mapController = MapController();
  final MerchantService _merchantService = MerchantService();
  final ThematicRouteService _routeService = ThematicRouteService();
  final TextEditingController _searchController = TextEditingController();

  String _username = "Customer";
  LatLng? _currentLocation;
  List<MerchantModel> _merchants = [];
  ThematicRouteModel? _recommendedRoute;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override // Tambahkan @override di sini
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    final name = await SharedPrefHelper.getUsername();
    await _getUserLocation();

    try {
      final merchantRes = await _merchantService.getAllMerchants();
      final routeRes = await _routeService.getAllThematicRoutes();

      if (merchantRes['success'] == true) {
        final List<dynamic> mData = merchantRes['data'];
        _merchants = mData.map((e) => MerchantModel.fromJson(e)).toList();
      }

      if (routeRes['success'] == true) {
        final List<dynamic> rData = routeRes['data'];
        if (rData.isNotEmpty) {
          _recommendedRoute = ThematicRouteModel.fromJson(rData[0]); 
        }
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
    }

    if (mounted) {
      setState(() {
        _username = name ?? "Customer";
        _isLoading = false;
      });
    }
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Position position = await Geolocator.getCurrentPosition();
    _currentLocation = LatLng(position.latitude, position.longitude);
  }

  void _recenterMap() {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 15.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Stack(
        children: [
          _buildMap(),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildHeaderAndSearch(),
          ),
          Positioned(
            bottom: 120, 
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton.extended(
                  onPressed: _recenterMap,
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF003D33),
                  icon: const Icon(Icons.my_location),
                  label: const Text("Pusatkan kembali", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                if (_recommendedRoute != null) _buildRecommendedRouteCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    // Bekasi Regency, West Java
    final centerPos = _currentLocation ?? const LatLng(-6.3262, 107.1352);

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: centerPos,
        initialZoom: 15.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.app',
        ),
        MarkerLayer(
          markers: [
            if (_currentLocation != null)
              Marker(
                point: _currentLocation!,
                width: 60,
                height: 60,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFAEEA00).withOpacity(0.5), 
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: const Color(0xFFAEEA00),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                    ),
                  ),
                ),
              ),
            ..._merchants.where((m) => m.latitude != null && m.longitude != null).map((merchant) {
              return Marker(
                point: LatLng(merchant.latitude!.toDouble(), merchant.longitude!.toDouble()),
                width: 120,
                height: 80,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFAEEA00),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.restaurant, color: Color(0xFF003D33), size: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      merchant.namaBisnis,
                      style: const TextStyle(
                        backgroundColor: Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  // --- BAGIAN YANG DIPERBAIKI ---
  Widget _buildHeaderAndSearch() {
    return Column(
      children: [
        // 1. Kotak Hijau Atas
        Container(
          padding: EdgeInsets.only(
            // Memberi jarak ekstra agar tidak tertutup notch/status bar HP
            top: MediaQuery.of(context).padding.top + 16, 
            left: 20, 
            right: 20, 
            bottom: 30,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF003D33),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: Color(0xFFAEEA00),
                child: Icon(Icons.person, color: Color(0xFF003D33), size: 30),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Halo, $_username",
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Temukan cerita di balik setiap sudut kota Jember", 
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {}, 
                icon: const Icon(Icons.notifications, color: Colors.white),
              )
            ],
          ),
        ),

        // 2. Search Bar & Filter Chips (Overlap di bawah header)
        Transform.translate(
          offset: const Offset(0, -20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                  ),
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            // Ganti dengan SearchResultsPage jika itu nama class-mu
                            builder: (context) => SearchResultsPage(query: value.trim()), 
                          ),
                        );
                        _searchController.clear();
                      }
                    },
                    decoration: const InputDecoration(
                      hintText: "Cari Legenda Kuliner atau Jalur...",
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Filter Chips
                // SingleChildScrollView(
                //   scrollDirection: Axis.horizontal,
                //   child: Row(
                //     children: [
                //       _buildChip("Semua", true),
                //       const SizedBox(width: 8),
                //       _buildChip("Legenda Kuliner", false),
                //       const SizedBox(width: 8),
                //       _buildChip("Bengkel Kriya", false),
                //     ],
                //   ),
                // )
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Aktifkan kembali fungsi pembuatan Chip
  // Widget _buildChip(String label, bool isSelected) {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //     decoration: BoxDecoration(
  //       color: isSelected ? const Color(0xFFAEEA00) : Colors.white,
  //       borderRadius: BorderRadius.circular(20),
  //       boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
  //     ),
  //     child: Text(
  //       label,
  //       style: TextStyle(
  //         color: isSelected ? const Color(0xFF003D33) : Colors.grey[700],
  //         fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
  //       ),
  //     ),
  //   );
  // }

  Widget _buildRecommendedRouteCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 100,
              height: 80,
              color: Colors.grey[300],
              child: const Icon(Icons.map, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _recommendedRoute!.judulRute,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  _recommendedRoute!.deskripsi,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.route, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text("${_recommendedRoute!.panjangRute ?? 0} km", style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFAEEA00),
                        foregroundColor: const Color(0xFF003D33),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        minimumSize: const Size(0, 30),
                      ),
                      child: const Text("Lihat", style: TextStyle(fontWeight: FontWeight.bold)),
                    )
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}