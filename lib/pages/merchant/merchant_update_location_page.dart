import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../helpers/shared_pref_helper.dart';
import '../../services/merchant_service.dart';

class MerchantUpdateLocationPage extends StatefulWidget {
  final LatLng? initialLocation;

  const MerchantUpdateLocationPage({super.key, this.initialLocation});

  @override
  State<MerchantUpdateLocationPage> createState() => _MerchantUpdateLocationPageState();
}

class _MerchantUpdateLocationPageState extends State<MerchantUpdateLocationPage> {
  final MapController _mapController = MapController();
  final MerchantService _merchantService = MerchantService();

  LatLng? _currentCenter;
  bool _isLoading = false;
  bool _isGettingLocation = false;

  static const Color tealDark = Color(0xFF0D3B2E);
  static const Color limeGreen = Color(0xFFAEEA00);

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _currentCenter = widget.initialLocation;
    } else {
      _currentCenter = const LatLng(-7.797068, 110.370529); // Default Jogja
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Layanan lokasi dinonaktifkan.')),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Izin lokasi ditolak.')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin lokasi ditolak permanen.')),
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final newLoc = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentCenter = newLoc;
      });
      _mapController.move(newLoc, 15.0);
    } catch (e) {
      debugPrint("Error getting location: $e");
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _saveLocation() async {
    if (_currentCenter == null) return;

    setState(() => _isLoading = true);
    try {
      final userId = await SharedPrefHelper.getUserId() ?? 0;
      int merchantId = 0;
      
      // Get the correct merchant ID for this user
      final merchantRes = await _merchantService.getAllMerchants();
      if (merchantRes['success'] == true) {
        final List<dynamic> mList = merchantRes['data'];
        final myMerchant = mList.firstWhere(
          (m) => m['user_id'].toString() == userId.toString(),
          orElse: () => null,
        );
        if (myMerchant != null) {
          merchantId = int.tryParse(myMerchant['id'].toString()) ?? 0;
        }
      }

      if (merchantId == 0) {
        throw Exception("Gagal menemukan data usaha merchant Anda.");
      }

      final response = await _merchantService.updateMerchantLocation(
        id: merchantId,
        latitude: _currentCenter!.latitude,
        longitude: _currentCenter!.longitude,
      );

      if (!mounted) return;

      if (response['success'] == true || response['status'] == 'success' || response['message']?.toString().toLowerCase().contains('berhasil') == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lokasi berhasil diperbarui!')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui: ${response["message"] ?? "API Error"}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terjadi kesalahan saat menyimpan lokasi')),
      );
      debugPrint("Save location error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1A1A2E), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Pinpoint Lokasi',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A2E),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location, color: tealDark),
            onPressed: _isGettingLocation ? null : _getCurrentLocation,
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter!,
              initialZoom: 15.0,
              onPositionChanged: (position, hasGesture) {
                if (hasGesture && position.center != null) {
                  setState(() {
                    _currentCenter = position.center;
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.litera.news.app',
              ),
            ],
          ),
          
          // Center Marker Pin
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40.0), // Adjust to make the pin point to the center
              child: Icon(
                Icons.location_on,
                size: 50,
                color: Colors.red[600],
              ),
            ),
          ),

          if (_isGettingLocation)
            const Center(
              child: CircularProgressIndicator(color: tealDark),
            ),

          // Bottom Sheet / Action Card
          Positioned(
            left: 20,
            right: 20,
            bottom: 30,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.location_on, color: Colors.blue[600], size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Koordinat Baru',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1A1A2E),
                              ),
                            ),
                            Text(
                              _currentCenter != null 
                                  ? '${_currentCenter!.latitude.toStringAsFixed(5)}, ${_currentCenter!.longitude.toStringAsFixed(5)}'
                                  : 'Memuat...',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tealDark,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              'Simpan Lokasi',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: limeGreen,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
