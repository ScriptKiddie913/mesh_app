import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/mesh_service.dart';
import '../../utils/theme.dart';

class IdentityScreen extends StatelessWidget {
  const IdentityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Identity & Trust')),
      body: Consumer<MeshService>(
        builder: (context, mesh, _) {
          final peers = [...mesh.peers]..sort((a, b) => a.username.compareTo(b.username));
          if (peers.isEmpty) {
            return const Center(child: Text('No peer identities yet'));
          }
          return ListView.builder(
            itemCount: peers.length,
            itemBuilder: (context, index) {
              final p = peers[index];
              final trust = _trustFromSignal(p.signalStrength, p.connected);
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _trustColor(trust).withValues(alpha: 0.2),
                    child: Text(p.username.isNotEmpty ? p.username[0].toUpperCase() : '?'),
                  ),
                  title: Text(p.username),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Role: ${p.connected ? 'relay-candidate' : 'guest'}'),
                      const SizedBox(height: 6),
                      _TrustBar(score: trust),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  int _trustFromSignal(double rssi, bool connected) {
    final base = connected ? 50 : 20;
    final strength = (100 + rssi).clamp(0, 50).toInt();
    return (base + strength).clamp(0, 100);
  }

  Color _trustColor(int score) {
    if (score >= 70) return MeshTheme.accentG;
    if (score >= 40) return MeshTheme.accentY;
    return MeshTheme.accentR;
  }
}

class _TrustBar extends StatelessWidget {
  const _TrustBar({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final color = score >= 70
        ? MeshTheme.accentG
        : score >= 40
            ? MeshTheme.accentY
            : MeshTheme.accentR;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('TRUST', style: TextStyle(fontSize: 10, color: MeshTheme.textSec)),
            const Spacer(),
            Text('$score', style: TextStyle(fontSize: 10, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        Stack(
          children: [
            Container(height: 3, color: MeshTheme.border),
            FractionallySizedBox(
              widthFactor: score / 100,
              child: Container(height: 3, color: color),
            ),
          ],
        ),
      ],
    );
  }
}
