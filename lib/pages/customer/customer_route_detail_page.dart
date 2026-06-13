import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/route_detail.dart';
import '../../services/route_detail_service.dart';

class CustomerRouteDetailPage extends StatefulWidget {
  final int thematicRouteId;
  final String judulRute;
  final LatLng? focusLocation;

  const CustomerRouteDetailPage({
    super.key,
    required this.thematicRouteId,
    required this.judulRute,
    this.focusLocation,
  });

  @override
  State<CustomerRouteDetailPage> createState() => _CustomerRouteDetailPageState();
}

class _CustomerRouteDetailPageState extends State<CustomerRouteDetailPage> {
  final RouteDetailService _routeDetailService = RouteDetailService();
  final MapController _mapController = MapController();

  LatLng? _currentLocation;
  List<RouteDetailModel> _routePoints = [];
  List<LatLng> _polylineCoordinates = [];
  
  bool _isLoading = true;
  int _currentStep = 0; 
  bool _isRouteFinished = false; 
  StreamSubscription<Position>? _positionStreamSubscription; 

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initData() async {
    setState(() => _isLoading = true);
    await _getUserLocation();
    await _fetchRouteDetails();
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

  // Meminta data rute berkelok dari OSRM
  Future<List<LatLng>> _getRoadRoute(List<LatLng> waypoints) async {
    if (waypoints.length < 2) return waypoints;
    try {
      String coordinatesString = waypoints.map((point) => '${point.longitude},${point.latitude}').join(';');
      final url = Uri.parse('http://router.project-osrm.org/route/v1/driving/$coordinatesString?geometries=geojson');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List routeCoordinates = data['routes'][0]['geometry']['coordinates'];
        return routeCoordinates.map((c) => LatLng(c[1], c[0])).toList();
      }
    } catch (e) {
      debugPrint("Gagal mengambil rute OSRM: $e");
    }
    return waypoints;
  }

  Future<void> _fetchRouteDetails() async {
    try {
      final response = await _routeDetailService.getAllRouteDetails();
      if (response['success'] == true) {
        final List<dynamic> data = response['data'];
        
        _routePoints = data
            .map((json) => RouteDetailModel.fromJson(json))
            .where((detail) => detail.thematicRouteId == widget.thematicRouteId)
            .toList();

        if (widget.focusLocation != null) {
          int focusIndex = _routePoints.indexWhere((p) => 
            p.latitude == widget.focusLocation!.latitude && p.longitude == widget.focusLocation!.longitude);
          if (focusIndex != -1) _currentStep = focusIndex;
        }

        await _calculateCurrentLeg();
      }
    } catch (e) {
      debugPrint("Error loading route details: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- LOGIKA MENGHITUNG 1 RUAS JALAN DARI LOKASI USER SAAT INI ---
  Future<void> _calculateCurrentLeg() async {
    if (_routePoints.isEmpty || _currentStep >= _routePoints.length) return;

    // SELALU gunakan lokasi GPS user saat ini sebagai titik awal
    LatLng startPoint = _currentLocation ?? const LatLng(-8.1721, 113.6995); 

    // Tentukan Titik Akhir (Destination)
    final targetDetail = _routePoints[_currentStep];
    LatLng endPoint = LatLng(targetDetail.latitude.toDouble(), targetDetail.longitude.toDouble());

    // Minta OSRM menggambar garis di antara 2 titik tersebut
    List<LatLng> legWaypoints = [startPoint, endPoint];
    final routeLine = await _getRoadRoute(legWaypoints);

    setState(() {
      _polylineCoordinates = routeLine;
    });

    // Pindahkan kamera menyorot titik tujuan
    _mapController.move(endPoint, 15.0);
  }

  // --- LOGIKA SAAT TOMBOL "SELESAIKAN RUTE" DITEKAN ---
  void _nextStep() async {
    if (_currentStep < _routePoints.length - 1) {
      // Tampilkan loading karena kita harus mencari lokasi GPS terbaru user
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.green)),
      );

      // Ambil lokasi GPS paling update sebelum menggambar rute ke tujuan berikutnya
      await _getUserLocation(); 
      
      if (!mounted) return;
      Navigator.pop(context); // Tutup loading

      setState(() {
        _currentStep++;
        _polylineCoordinates.clear(); // Bersihkan garis lama
      });
      await _calculateCurrentLeg();
    } else {
      setState(() {
        _isRouteFinished = true;
        _polylineCoordinates.clear(); 
      });
      
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Selamat! 🎉"),
          content: const Text("Anda telah menyelesaikan seluruh perjalanan pada rute tematik ini!"),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); 
                Navigator.pop(context); 
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text("Tutup", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    LatLng initialCenter = _currentLocation ?? const LatLng(-8.1721, 113.6995);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF003D33),
        foregroundColor: Colors.white,
        title: Text(widget.judulRute),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _routePoints.isEmpty
              ? const Center(child: Text("Belum ada rute/titik lokasi pada rute ini."))
              : Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: initialCenter,
                        initialZoom: 14.5,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.litera.news.app',
                        ),
                        
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _polylineCoordinates,
                              color: const Color(0xFF003D33),
                              strokeWidth: 5.0,
                            ),
                          ],
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

                            ..._routePoints.asMap().entries.map((entry) {
                              int index = entry.key;
                              var point = entry.value;
                              LatLng position = LatLng(point.latitude.toDouble(), point.longitude.toDouble());
                              
                              bool isCompleted = index < _currentStep; 
                              bool isCurrentTarget = index == _currentStep && !_isRouteFinished; 

                              Color markerColor = isCurrentTarget 
                                  ? Colors.red 
                                  : (isCompleted ? Colors.grey : const Color(0xFFAEEA00));
                              Color textColor = (isCurrentTarget || isCompleted) ? Colors.white : const Color(0xFF003D33);

                              return Marker(
                                point: position,
                                width: 100,
                                height: 70,
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: markerColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      child: Text(
                                        "${index + 1}",
                                        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      point.namaBisnis,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        backgroundColor: Colors.white70,
                                        decoration: isCompleted ? TextDecoration.lineThrough : null, 
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ],
                    ),

                    if (!_isRouteFinished)
                      Positioned(
                        bottom: 30,
                        left: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                  backgroundColor: Colors.red,
                                    radius: 16,
                                    child: Text("${_currentStep + 1}", style: const TextStyle(color: Colors.white, fontSize: 14)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text("Menuju Destinasi:", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                        Text(
                                          _routePoints[_currentStep].namaBisnis,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _nextStep,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF003D33),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text("Selesaikan Destinasi Ini", style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}