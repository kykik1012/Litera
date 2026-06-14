import 'dart:async';
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
import '../../services/product_service.dart';
import '../../services/user_service.dart';
import '../../constants/api.dart';
import 'customer_route_preview_page.dart';
import 'customer_merchant_detail_page.dart';

class CustomerDashboardPage extends StatefulWidget {
  const CustomerDashboardPage({super.key});

  @override
  State<CustomerDashboardPage> createState() => _CustomerDashboardPageState();
}

class _CustomerDashboardPageState extends State<CustomerDashboardPage> {
  final MapController _mapController = MapController();
  final MerchantService _merchantService = MerchantService();
  final ThematicRouteService _routeService = ThematicRouteService();
  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();

  String _username = "Customer";
  String? _profilePicture;
  LatLng? _currentLocation;
  List<MerchantModel> _merchants = [];
  List<MerchantModel> _filteredMerchants = [];
  List<dynamic> _allProducts = [];
  List<String> _categories = ["Semua"];
  String _selectedCategory = "Semua";
  
  MerchantModel? _selectedMerchant;
  List<ThematicRouteModel> _routes = [];
  final PageController _pageController = PageController(viewportFraction: 0.95);
  bool _isLoading = true;
  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override // Tambahkan @override di sini
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initData() async {
    final name = await SharedPrefHelper.getUsername();
    final userId = await SharedPrefHelper.getUserId() ?? 0;
    await _getUserLocation();

    try {
      if (userId != 0) {
        final userService = UserService();
        final userRes = await userService.getUserById(userId);
        if (userRes["success"] == true) {
          _profilePicture = userRes["data"]["profile_picture"];
        }
      }
      
      final merchantRes = await _merchantService.getAllMerchants();
      final routeRes = await _routeService.getAllThematicRoutes();
      final productRes = await _productService.getAllProducts();

      if (merchantRes['success'] == true) {
        final List<dynamic> mData = merchantRes['data'];
        _merchants = mData.map((e) => MerchantModel.fromJson(e)).toList();
        _filteredMerchants = List.from(_merchants);
      }

      if (routeRes['success'] == true) {
        final List<dynamic> rData = routeRes['data'];
        if (rData.isNotEmpty) {
          _routes = rData.map((e) => ThematicRouteModel.fromJson(e)).where((r) => !r.isDelete).toList();
        }
      }

      if (productRes['success'] == true) {
        _allProducts = productRes['data'];
        final Set<String> catSet = {};
        for (var p in _allProducts) {
          if (p['category_name'] != null && p['category_name'].toString().isNotEmpty) {
            catSet.add(p['category_name'].toString());
          }
        }
        _categories = ["Semua", ...catSet.toList()];
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

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position newPosition) {
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(newPosition.latitude, newPosition.longitude);
        });
      }
    });
  }

  void _recenterMap() {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 15.0);
    }
  }

  void _filterMerchantsByCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _selectedMerchant = null; // Reset selection
      if (category == "Semua") {
        _filteredMerchants = List.from(_merchants);
      } else {
        // Cari nama_bisnis dari product yang punya category_name tersebut
        final Set<String> merchantNamesWithCat = {};
        for (var p in _allProducts) {
          if (p['category_name'] == category && p['nama_bisnis'] != null) {
            merchantNamesWithCat.add(p['nama_bisnis'].toString().toLowerCase());
          }
        }
        
        _filteredMerchants = _merchants.where((m) {
          return merchantNamesWithCat.contains(m.namaBisnis.toLowerCase());
        }).toList();
      }
    });
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
                ElevatedButton.icon(
                  onPressed: _recenterMap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF003D33),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 4,
                  ),
                  icon: const Icon(Icons.my_location, size: 18),
                  label: const Text("Pusatkan kembali", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                if (_selectedMerchant != null)
                  _buildSelectedMerchantCard()
                else if (_routes.isNotEmpty) 
                  _buildRecommendedRouteSlider(),
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
          userAgentPackageName: 'com.litera.news.app',
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
            ..._filteredMerchants.where((m) => m.latitude != null && m.longitude != null).map((merchant) {
              return Marker(
                point: LatLng(merchant.latitude!.toDouble(), merchant.longitude!.toDouble()),
                width: 120,
                height: 80,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedMerchant = merchant;
                    });
                  },
                  child: Column(
                    children: [
                      Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: merchant.status.toLowerCase() == 'tutup' ? Colors.grey : const Color(0xFFAEEA00),
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
            gradient: LinearGradient(
              colors: [Color(0xFF0D3B2E), Color(0xFF1A8A7A)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: Row(
            children: [
              ClipOval(
                child: _profilePicture != null && _profilePicture!.isNotEmpty
                    ? Image.network(
                        Api.getImageUrl(_profilePicture),
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 48, height: 48, color: const Color(0xFFAEEA00),
                          child: const Icon(Icons.person, color: Color(0xFF003D33), size: 30),
                        ),
                      )
                    : Container(
                        width: 48, height: 48, color: const Color(0xFFAEEA00),
                        child: const Icon(Icons.person, color: Color(0xFF003D33), size: 30),
                      ),
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
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: GestureDetector(
                          onTap: () => _filterMerchantsByCategory(cat),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFAEEA00) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (cat != "Semua") ...[
                                  Icon(
                                    cat.toLowerCase().contains("kuliner") || cat.toLowerCase().contains("makanan") ? Icons.restaurant : Icons.category,
                                    size: 14,
                                    color: isSelected ? const Color(0xFF003D33) : Colors.grey[600],
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Text(
                                  cat,
                                  style: TextStyle(
                                    color: isSelected ? const Color(0xFF003D33) : Colors.grey[700],
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                )
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

  Widget _buildRecommendedRouteSlider() {
    return SizedBox(
      height: 130, // Disesuaikan agar seukuran dengan card merchant
      child: PageView.builder(
        controller: _pageController,
        itemCount: _routes.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: _buildRouteCard(_routes[index]),
          );
        },
      ),
    );
  }

  Widget _buildRouteCard(ThematicRouteModel route) {
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
            child: route.imageUrl != null && route.imageUrl!.isNotEmpty
                ? Image.network(
                    route.imageUrl!,
                    width: 100,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 100, height: 80, color: Colors.grey[300],
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  )
                : Container(
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  route.judulRute,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  route.deskripsi,
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
                        Text("${route.panjangRute ?? 0} km", style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CustomerRoutePreviewPage(
                              thematicRouteId: int.parse(route.id),
                              judulRute: route.judulRute,
                              deskripsiRute: route.deskripsi,
                            ),
                          ),
                        );
                      },
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

  Widget _buildSelectedMerchantCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
      ),
      padding: const EdgeInsets.all(12),
      child: Stack(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _selectedMerchant!.imageUrl != null && _selectedMerchant!.imageUrl!.isNotEmpty
                    ? Image.network(
                        _selectedMerchant!.imageUrl!,
                        width: 100,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 100, height: 80, color: Colors.grey[300],
                          child: const Icon(Icons.store, color: Colors.grey),
                        ),
                      )
                    : Container(
                        width: 100,
                        height: 80,
                        color: Colors.grey[300],
                        child: const Icon(Icons.store, color: Colors.grey),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _selectedMerchant!.namaBisnis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedMerchant!.deskripsi ?? "Merchant Litera",
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
                            const Icon(Icons.storefront, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(_selectedMerchant!.status, style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CustomerMerchantDetailPage(merchant: _selectedMerchant!),
                              ),
                            );
                          },
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
          Positioned(
            top: -10,
            right: -10,
            child: IconButton(
              icon: const Icon(Icons.close, size: 20, color: Colors.grey),
              onPressed: () {
                setState(() {
                  _selectedMerchant = null;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}