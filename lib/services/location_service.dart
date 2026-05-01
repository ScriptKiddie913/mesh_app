import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'mesh_service.dart';
import '../models/enums.dart';

class LocationService {
  final MeshService _mesh;
  StreamSubscription<Position>? _positionSubscription;
  bool isBroadcasting = false;

  LocationService(this._mesh);

  void toggleBroadcasting(bool value) {
    isBroadcasting = value;
  }

  Future<void> startLocationSharing() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    
    if (permission == LocationPermission.deniedForever) return;

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // 10 meters
      ),
    ).listen((Position position) {
      _broadcastLocation(position);
    });
  }

  void _broadcastLocation(Position pos) {
    if (!isBroadcasting) return;
    _mesh.sendMessage(
      receiverId: '', // Broadcast
      type: 'location_update',
      content: '${pos.latitude},${pos.longitude}',
      priority: MessagePriority.normal,
    );
  }

  void stop() {
    _positionSubscription?.cancel();
  }
}
