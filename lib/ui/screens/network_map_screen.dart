import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/peer.dart';
import '../../services/storage_service.dart';
import '../../services/mesh_service.dart';
import '../../utils/theme.dart';

class NetworkMapScreen extends StatelessWidget {
  const NetworkMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Network Map')),
      body: Consumer2<MeshService, StorageService>(
        builder: (context, mesh, storage, _) {
          final peers = mesh.peers;
          final myId = storage.getDeviceId();
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: MeshTheme.bg0,
                border: Border.all(color: MeshTheme.border),
              ),
              child: CustomPaint(
                painter: _NetworkPainter(peers: peers, myId: myId),
                child: const SizedBox.expand(),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NetworkPainter extends CustomPainter {
  final List<Peer> peers;
  final String myId;
  final Map<String, Offset> _positions = {};

  _NetworkPainter({required this.peers, required this.myId});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    if (peers.isEmpty) {
      _drawNode(canvas, center, 'ME', MeshTheme.accent, 20);
      return;
    }

    for (int i = 0; i < peers.length; i++) {
      final angle = (2 * pi * i) / peers.length;
      _positions[peers[i].id] = Offset(
        center.dx + 120 * cos(angle),
        center.dy + 120 * sin(angle),
      );
    }

    final edgePaint = Paint()
      ..color = MeshTheme.border
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (final peer in peers) {
      if (!peer.connected) continue;
      final pos = _positions[peer.id]!;
      canvas.drawLine(center, pos, edgePaint);
    }

    _drawNode(canvas, center, 'ME', MeshTheme.accent, 20);

    for (final peer in peers) {
      final pos = _positions[peer.id]!;
      final label = peer.username.isNotEmpty ? peer.username[0].toUpperCase() : '?';
      _drawNode(
        canvas,
        pos,
        label,
        peer.connected ? MeshTheme.accentG : MeshTheme.textSec,
        14,
      );
    }
  }

  void _drawNode(Canvas canvas, Offset pos, String label, Color color, double radius) {
    final rect = Rect.fromCenter(center: pos, width: radius * 2, height: radius * 2);
    canvas.drawRect(rect, Paint()..color = MeshTheme.bg1);
    canvas.drawRect(
      rect,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(color: MeshTheme.textPri, fontSize: 10, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, pos - Offset(painter.width / 2, painter.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
