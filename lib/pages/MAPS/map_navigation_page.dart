import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

// Pastikan import model dan service sudah sesuai path kamu
import 'package:litera/services/route_detail_service.dart';
import '../../models/route_detail.dart';

class MapNavigationPage extends StatefulWidget {
  // Tambahkan parameter ini agar halaman tahu rute mana yang dibuka
  final int thematicRouteId; 

  const MapNavigationPage({super.key, required this.thematicRouteId});

  @override
  _MapNavigationPageState createState() => _MapNavigationPageState();
}

class _MapNavigationPageState extends State<MapNavigationPage> {
  LatLng? userLocation;
  List<LatLng> routePoints = []; 
  
  int currentTargetIndex = 0; 
  bool isAllCompleted = false;
  bool isLoading = true; // Tambahan untuk indikator loading

  // Ganti List dummy dengan List dari Model
  List<RouteDetailModel> routeLocations = [];

  final RouteDetailService _routeDetailService = RouteDetailService();

  @override
  void initState() {
    super.initState();
    _fetchDataAndInitNavigation();
  }

  // Fungsi gabungan untuk Fetch API lalu Init GPS
  Future<void> _fetchDataAndInitNavigation() async {
    try {
      // 1. Fetch data dari API
      final response = await _routeDetailService.getAllRouteDetails();
      
      if (response['success'] == true) {
        List<dynamic> data = response['data'];
        
        // Map ke model, lalu filter berdasarkan thematicRouteId yang dikirim dari Card Admin
        routeLocations = data
            .map((json) => RouteDetailModel.fromJson(json))
            .where((detail) => detail.thematicRouteId == widget.thematicRouteId)
            .toList();
      }

      // 2. Dapatkan Lokasi User (Kode asli milikmu)
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return; 

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      if (!mounted) return;

      setState(() {
        userLocation = LatLng(position.latitude, position.longitude);
      });

      // 3. Hitung Jarak dan Urutkan
      if (routeLocations.isNotEmpty && userLocation != null) {
        for (var place in routeLocations) {
          double distance = Geolocator.distanceBetween(
            userLocation!.latitude,
            userLocation!.longitude,
            place.latitude.toDouble(), // Convert num ke double agar tidak error
            place.longitude.toDouble(),
          );
          place.distanceToUser = distance; 
        }

        // Urutkan lokasi dari yang terdekat
        routeLocations.sort((a, b) => a.distanceToUser.compareTo(b.distanceToUser));

        // Panggil rute navigasi garis biru
        await _getRouteToCurrentTarget();
      }

      setState(() {
        isLoading = false; // Matikan loading
      });

    } catch (e) {
      debugPrint("Error: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _getRouteToCurrentTarget() async {
    if (userLocation == null || routeLocations.isEmpty || isAllCompleted) return;

    final target = routeLocations[currentTargetIndex];
    final start = '${userLocation!.longitude},${userLocation!.latitude}';
    final end = '${target.longitude},${target.latitude}';
    
    final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/$start;$end?geometries=geojson');

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final geometry = data['routes'][0]['geometry']['coordinates'];
      
      setState(() {
        routePoints = geometry
            .map<LatLng>((coord) => LatLng(coord[1], coord[0]))
            .toList();
      });
    }
  }

  void _goToNextTarget() async {
    Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
    
    setState(() {
      userLocation = LatLng(position.latitude, position.longitude);
      currentTargetIndex++; 
      
      if (currentTargetIndex >= routeLocations.length) {
        isAllCompleted = true;
        routePoints.clear(); 
      }
    });

    if (!isAllCompleted) {
      await _getRouteToCurrentTarget();
    }
  }

  List<Marker> _buildMapMarkers() {
    List<Marker> markers = [];

    if (userLocation != null) {
      markers.add(
        Marker(
          width: 50, height: 50,
          point: userLocation!,
          child: const Icon(Icons.person_pin_circle, color: Colors.red, size: 40),
        )
      );
    }

    for (var i = 0; i < routeLocations.length; i++) {
      Color iconColor;
      if (i < currentTargetIndex) {
        iconColor = Colors.grey; 
      } else if (i == currentTargetIndex && !isAllCompleted) {
        iconColor = Colors.green; 
      } else {
        iconColor = Colors.blue; 
      }

      markers.add(
        Marker(
          width: 60, 
          height: 60, 
          // Ambil titik lat/lng dari model
          point: LatLng(routeLocations[i].latitude.toDouble(), routeLocations[i].longitude.toDouble()),
          child: Column(
            mainAxisSize: MainAxisSize.min, 
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black12),
                ),
                child: Text(
                  '${i + 1}', 
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 12),
                ),
              ),
              Icon(Icons.location_on, color: iconColor, size: 30),
            ],
          ),
        )
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Navigasi Rute Membatik')),
      body: isLoading || userLocation == null
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              options: MapOptions(
                initialCenter: userLocation!,
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
                      points: routePoints,
                      strokeWidth: 5.0,
                      color: Colors.blueAccent, 
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: _buildMapMarkers(),
                ),
              ],
            ),
      floatingActionButton: !isAllCompleted && userLocation != null && routeLocations.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _goToNextTarget,
              label: Text('Sampai Tujuan ${currentTargetIndex + 1}'),
              icon: const Icon(Icons.check_circle),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            )
          : isAllCompleted && routeLocations.isNotEmpty
              ? FloatingActionButton.extended(
                  onPressed: () {},
                  label: const Text('Rute Selesai'),
                  icon: const Icon(Icons.done_all),
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                )
              : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}