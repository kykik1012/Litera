import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../../models/merchant.dart';

class CustomerSingleRoutePage extends StatefulWidget {
  final MerchantModel merchant;

  const CustomerSingleRoutePage({super.key, required this.merchant});

  @override
  State<CustomerSingleRoutePage> createState() => _CustomerSingleRoutePageState();
}

class _CustomerSingleRoutePageState extends State<CustomerSingleRoutePage> {
  final MapController _mapController = MapController();
  
  late LatLng _destinationLocation;
  LatLng? _currentLocation;
  List<LatLng> _routePoints = [];
  
  bool _isLoadingMap = true;
  String _statusMessage = "Mencari lokasimu...";
  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    // 1. Set lokasi tujuan dari data merchant
    double lat = widget.merchant.latitude?.toDouble() ?? 0.0;
    double lng = widget.merchant.longitude?.toDouble() ?? 0.0;
    _destinationLocation = LatLng(lat, lng);
    
    // 2. Mulai proses pelacakan lokasi dan pembuatan rute
    _initRoute();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initRoute() async {
    try {
      await _getCurrentLocation();
      if (_currentLocation != null) {
        setState(() => _statusMessage = "Menghitung rute tercepat...");
        await _fetchRouteFromOSRM();
      }
    } catch (e) {
      debugPrint(e.toString());
      if (mounted) {
        setState(() => _statusMessage = "Gagal memuat rute: $e");
      }
    } finally {
      if (mounted) setState(() => _isLoadingMap = false);
    }
  }

  // --- FUNGSI MENDAPATKAN LOKASI SAAT INI ---
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('GPS tidak aktif.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Izin lokasi ditolak.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Izin lokasi ditolak permanen.');
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    _currentLocation = LatLng(position.latitude, position.longitude);

    _positionStreamSubscription ??= Geolocator.getPositionStream(
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

  // --- FUNGSI MENGAMBIL GARIS RUTE DARI OSRM API ---
  Future<void> _fetchRouteFromOSRM() async {
    if (_currentLocation == null) return;

    // Format OSRM: longitude,latitude
    final String start = "${_currentLocation!.longitude},${_currentLocation!.latitude}";
    final String end = "${_destinationLocation.longitude},${_destinationLocation.latitude}";
    
    // Menggunakan API OSRM publik gratis
    final String url = "https://router.project-osrm.org/route/v1/driving/$start;$end?geometries=geojson";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> coords = data['routes'][0]['geometry']['coordinates'];
      
      setState(() {
        // OSRM mengembalikan [longitude, latitude], jadi kita balik posisinya saat memasukkan ke LatLng
        _routePoints = coords.map((c) => LatLng(c[1], c[0])).toList();
      });
    } else {
      throw Exception('Gagal mengambil data rute dari server peta.');
    }
  }

  void _recenterMap() {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 15.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF003D33),
        foregroundColor: Colors.white,
        title: Text("Rute ke ${widget.merchant.namaBisnis}"),
      ),
      body: Stack(
        children: [
          // --- PETA FLUTTER MAP ---
          if (_currentLocation != null && !_isLoadingMap)
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentLocation!,
                initialZoom: 14.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.litera.news.app',
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: Colors.blueAccent, // Warna garis rute
                      strokeWidth: 5.0,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    // Marker Lokasi Saat Ini (Mulai)
                    Marker(
                      point: _currentLocation!,
                      width: 50,
                      height: 50,
                      child: const Icon(Icons.my_location, color: Colors.blue, size: 30),
                    ),
                    // Marker Tujuan (Merchant)
                    Marker(
                      point: _destinationLocation,
                      width: 50,
                      height: 50,
                      child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                    ),
                  ],
                ),
              ],
            ),

          // --- LOADING SCREEN ---
          if (_isLoadingMap)
            Container(
              color: Colors.white.withOpacity(0.9),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFF003D33)),
                    const SizedBox(height: 16),
                    Text(_statusMessage, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),

          // --- TOMBOL RECENTER MAP ---
          if (!_isLoadingMap)
            Positioned(
              top: 20,
              right: 20,
              child: FloatingActionButton(
                heroTag: "btn_recenter",
                mini: true,
                backgroundColor: Colors.white,
                onPressed: _recenterMap,
                child: const Icon(Icons.my_location, color: Color(0xFF003D33)),
              ),
            ),

          // --- KARTU INFO MERCHANT ---
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFFAEEA00),
                      child: Icon(Icons.storefront, color: Color(0xFF003D33)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.merchant.namaBisnis, 
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF003D33)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Tujuan Navigasi", 
                            style: TextStyle(color: Colors.grey[600], fontSize: 12)
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}