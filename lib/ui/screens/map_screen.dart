import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../models/peer.dart';
import '../../services/mesh_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const LatLng _fallbackCenter = LatLng(0, 0);

  LatLng? _currentPosition;
  bool _isLoading = true;
  bool _isSatellite = false;
  String? _locationStatus;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _currentPosition ??= _fallbackCenter;
            _locationStatus = 'LOCATION SERVICES DISABLED';
            _isLoading = false;
          });
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _currentPosition ??= _fallbackCenter;
            _locationStatus = 'LOCATION PERMISSION UNAVAILABLE';
            _isLoading = false;
          });
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _locationStatus = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[MapScreen] Error getting location: $e');
      if (mounted) {
        setState(() {
          _currentPosition ??= _fallbackCenter;
          _locationStatus = 'USING FALLBACK MAP CENTER';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.satellite_alt_outlined, color: Color(0xFF00D1FF), size: 20),
            SizedBox(width: 8),
            Text(
              'TACTICAL MAP',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                letterSpacing: 2.0,
                fontSize: 16,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: const Color(0xFF00D1FF),
            height: 1.0,
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00D1FF).withValues(alpha: 0.5),
                    blurRadius: 4,
                  )
                ],
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isSatellite ? Icons.map : Icons.satellite,
              color: const Color(0xFFE6F1FF),
            ),
            tooltip: 'TOGGLE MAP STYLE',
            onPressed: () {
              setState(() {
                _isSatellite = !_isSatellite;
              });
            },
          ),
          Consumer<MeshService>(
            builder: (context, mesh, _) {
              return IconButton(
                icon: Icon(
                  mesh.isSharingLocation ? Icons.location_on : Icons.location_off_outlined,
                  color: mesh.isSharingLocation ? const Color(0xFFFF4D4F) : const Color(0xFFE6F1FF),
                ),
                tooltip: mesh.isSharingLocation ? 'STOP BROADCASTING' : 'BROADCAST LOCATION',
                onPressed: () {
                  mesh.toggleLocationSharing(!mesh.isSharingLocation);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        mesh.isSharingLocation ? 'LOCATION BROADCAST TERMINATED' : 'BROADCASTING LOCATION...',
                      ),
                      backgroundColor: const Color(0xFF112240),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Consumer<MeshService>(
            builder: (context, mesh, child) {
              final markers = <Marker>[];

              for (final entry in mesh.peerLocations.entries) {
                final peer = mesh.peers.firstWhere(
                  (p) => p.id == entry.key,
                  orElse: () => Peer(
                    id: entry.key,
                    username: 'UNKNOWN',
                    publicKeyHash: '',
                    signalStrength: 0,
                    lastSeen: DateTime.now(),
                    connected: false,
                  ),
                );
                markers.add(
                  Marker(
                    point: entry.value,
                    width: 60,
                    height: 60,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          peer.username.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFFFF4D4F),
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Icon(
                          Icons.person_pin_circle,
                          color: Color(0xFFFF4D4F),
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (_currentPosition != null) {
                markers.add(
                  Marker(
                    point: _currentPosition!,
                    width: 40,
                    height: 40,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF00D1FF).withValues(alpha: 0.2),
                            border: Border.all(
                              color: const Color(0xFF00D1FF).withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00D1FF),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00D1FF).withValues(alpha: 0.6),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return FlutterMap(
                options: MapOptions(
                  initialCenter: _currentPosition ?? _fallbackCenter,
                  initialZoom: 15.0,
                  minZoom: 2.0,
                  maxZoom: 19.0,
                ),
                children: [
                  TileLayer(
                    tileProvider: _isSatellite ? NetworkTileProvider() : AssetTileProvider(),
                    urlTemplate: _isSatellite
                        ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                        : 'assets/tiles/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.meshchat.p2p',
                    maxNativeZoom: _isSatellite ? 19 : 2,
                    errorTileCallback: (tile, error, stackTrace) {},
                  ),
                  MarkerLayer(markers: markers),
                ],
              );
            },
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _GridPainter(),
              ),
            ),
          ),
          if (!_isLoading && _locationStatus != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: SafeArea(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF112240).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF3A86FF).withValues(alpha: 0.35)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Text(
                      _locationStatus!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFE6F1FF),
                        letterSpacing: 1.2,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (_isLoading)
            Container(
              color: const Color(0xFF020C1B).withValues(alpha: 0.8),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        color: Color(0xFF00D1FF),
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ACQUIRING SATELLITE LOCK...',
                      style: TextStyle(
                        color: const Color(0xFF00D1FF).withValues(alpha: 0.8),
                        letterSpacing: 2.0,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _currentPosition != null
          ? Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF3A86FF), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00D1FF).withValues(alpha: 0.2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: FloatingActionButton(
                backgroundColor: const Color(0xFF112240),
                elevation: 0,
                onPressed: _initLocation,
                child: const Icon(Icons.my_location, color: Color(0xFF00D1FF)),
              ),
            )
          : null,
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3A86FF).withValues(alpha: 0.1)
      ..strokeWidth = 1.0;

    const double step = 50.0;

    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
