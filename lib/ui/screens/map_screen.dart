import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/mesh_service.dart';
import '../../utils/theme.dart';
import '../widgets/mesh_widgets.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  bool _isSatellite = true;
  LatLng? _myLocation;

  @override
  void initState() {
    super.initState();
    _fetchMyLocation();
  }

  Future<void> _fetchMyLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _myLocation = LatLng(pos.latitude, pos.longitude);
      });
      _mapController.move(_myLocation!, 15);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final mesh = context.watch<MeshService>();
    final isBroadcasting = mesh.locationService.isBroadcasting;

    return Scaffold(
      backgroundColor: MeshTheme.bg0,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: const BoxDecoration(
            color: MeshTheme.bg0,
            border: Border(bottom: BorderSide(color: MeshTheme.accent, width: 0.5)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.satellite_alt_outlined, color: MeshTheme.accent, size: 22),
                  const SizedBox(width: 12),
                  const Text(
                    'TACTICAL MAP',
                    style: TextStyle(
                      fontFamily: MeshTheme.fontMono,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(_isSatellite ? Icons.map_outlined : Icons.satellite_alt, color: Colors.white, size: 24),
                    onPressed: () => setState(() => _isSatellite = !_isSatellite),
                  ),
                  IconButton(
                    icon: Icon(isBroadcasting ? Icons.sensors : Icons.sensors_off, color: isBroadcasting ? MeshTheme.accent : Colors.white70, size: 24),
                    onPressed: () {
                      mesh.locationService.toggleBroadcasting(!isBroadcasting);
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _myLocation ?? const LatLng(0, 0),
              initialZoom: 15,
            ),
            children: [
                TileLayer(
                  urlTemplate: _isSatellite
                      ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                      : 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                ),
                MarkerLayer(
                  markers: [
                    if (_myLocation != null)
                      Marker(
                        point: _myLocation!,
                        width: 60,
                        height: 60,
                        child: _PulseMarker(color: MeshTheme.accent),
                      ),
                    ...mesh.peers.map((p) {
                      if (p.latitude == 0 && p.longitude == 0) return null;
                      return Marker(
                        point: LatLng(p.latitude, p.longitude),
                        width: 50,
                        height: 50,
                        child: Column(
                          children: [
                            Text(p.username.toUpperCase(), style: const TextStyle(fontSize: 8, color: Colors.white, backgroundColor: Colors.black54)),
                            Icon(Icons.location_on, color: p.connected ? MeshTheme.accentG : MeshTheme.accentR, size: 30),
                          ],
                        ),
                      );
                    }).whereType<Marker>(),
                  ],
                ),
            ],
          ),
          Positioned(
            bottom: 30,
            right: 20,
            child: GestureDetector(
              onTap: _fetchMyLocation,
              child: Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  color: MeshTheme.bg1.withOpacity(0.9),
                  shape: BoxShape.circle,
                  border: Border.all(color: MeshTheme.accent, width: 1.5),
                  boxShadow: [
                    BoxShadow(color: MeshTheme.accent.withOpacity(0.2), blurRadius: 10),
                  ],
                ),
                child: const Icon(Icons.my_location, color: MeshTheme.accent, size: 28),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseMarker extends StatefulWidget {
  final Color color;
  const _PulseMarker({required this.color});
  @override
  State<_PulseMarker> createState() => _PulseMarkerState();
}

class _PulseMarkerState extends State<_PulseMarker> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 45 * _controller.value,
              height: 45 * _controller.value,
              decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color.withOpacity(0.6 * (1 - _controller.value))),
            ),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle, 
                color: widget.color, 
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [BoxShadow(color: widget.color, blurRadius: 8)],
              ),
            ),
          ],
        );
      },
    );
  }
}
