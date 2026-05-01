import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/node_role.dart';
import '../../services/mesh_service.dart';
import '../../utils/theme.dart';

class NodeStatusScreen extends StatelessWidget {
  const NodeStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Node Status')),
      body: Consumer<MeshService>(
        builder: (context, mesh, _) {
          final role = mesh.nodeRole;
          final roleText = switch (role) {
            NodeRole.relay => 'RELAY',
            NodeRole.lowPowerRelay => 'LOW POWER RELAY',
            NodeRole.dormant => 'DORMANT',
            NodeRole.normal => 'NORMAL',
          };

          final roleColor = switch (role) {
            NodeRole.relay => MeshTheme.accentG,
            NodeRole.lowPowerRelay => MeshTheme.accentY,
            NodeRole.dormant => MeshTheme.textSec,
            NodeRole.normal => MeshTheme.accent,
          };

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _card(
                title: 'Node Role',
                value: roleText,
                color: roleColor,
              ),
              const SizedBox(height: 12),
              _card(
                title: 'Relay Count',
                value: mesh.relayedMessagesCount.toString(),
                color: MeshTheme.accent,
              ),
              const SizedBox(height: 12),
              _card(
                title: 'Connected Peers',
                value: mesh.peers.where((p) => p.connected).length.toString(),
                color: MeshTheme.accentG,
              ),
              const SizedBox(height: 12),
              _card(
                title: 'Battery',
                value: '${mesh.batteryLevel}%',
                color: mesh.batteryLevel > 30 ? MeshTheme.accentG : MeshTheme.accentR,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _card({required String title, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MeshTheme.bg1,
        border: Border.all(color: MeshTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: MeshTheme.textSec, fontSize: 12)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
