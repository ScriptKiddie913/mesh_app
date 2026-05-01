import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/enums.dart';

class RelayManager {
  static const int RELAY_THRESHOLD_PEERS = 3; 
  static const int LOW_POWER_THRESHOLD   = 2;
  static const int DORMANT_THRESHOLD     = 30; 

  NodeRole _currentRole = NodeRole.normal;
  Timer? _evaluationTimer;
  int _batteryLevel = 100;
  final Set<String> _connectedPeers = {};
  DateTime _lastActivity = DateTime.now();

  NodeRole get currentRole => _currentRole;

  void addPeer(String deviceId) {
    _connectedPeers.add(deviceId);
    recordActivity();
  }

  void removePeer(String deviceId) {
    _connectedPeers.remove(deviceId);
    recordActivity();
  }

  void recordActivity() {
    _lastActivity = DateTime.now();
  }

  void startEvaluation(VoidCallback onRoleChange) {
    _evaluationTimer?.cancel();
    _evaluationTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _evaluate(onRoleChange),
    );
  }

  void _evaluate(VoidCallback onRoleChange) {
    final connectedCount = _connectedPeers.length;
    final newRole = _computeRole(connectedCount);
    if (newRole != _currentRole) {
      _currentRole = newRole;
      onRoleChange();
    }
  }

  NodeRole _computeRole(int peers) {
    if (_batteryLevel < 15) return NodeRole.dormant;
    
    final idleMinutes = DateTime.now().difference(_lastActivity).inMinutes;
    if (idleMinutes >= DORMANT_THRESHOLD && peers == 0) return NodeRole.dormant;

    if (peers >= RELAY_THRESHOLD_PEERS) return NodeRole.relay;
    if (peers >= LOW_POWER_THRESHOLD) return NodeRole.lowPowerRelay;
    return NodeRole.normal;
  }

  void updateBattery(int level) {
    _batteryLevel = level;
  }

  void dispose() {
    _evaluationTimer?.cancel();
  }
}
