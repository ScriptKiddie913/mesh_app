import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/mesh_service.dart';
import 'chat_screen.dart';
import '../../utils/constants.dart';

class PeersScreen extends StatelessWidget {
  const PeersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.people, color: Colors.orange),
            SizedBox(width: 8),
            Text(kAppName),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<MeshService>().start(),
          ),
        ],
      ),
      body: Consumer<MeshService>(
        builder: (context, mesh, child) {
          final peers = mesh.peers..sort((a, b) => b.signalStrength.compareTo(a.signalStrength));
          return ListView.builder(
            itemCount: peers.length,
            itemBuilder: (context, i) {
              final peer = peers[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.withValues(alpha: 0.2),
                    child: Text(peer.username[0].toUpperCase()),
                  ),
                  title: Text(peer.username),
                  subtitle: Text('${peer.signalStrength.toStringAsFixed(0)} dBm • ${peer.connected ? 'Connected' : 'Offline'}'),
                  trailing: Icon(peer.connected ? Icons.wifi : Icons.wifi_off, color: peer.connected ? Colors.green : Colors.grey),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(peer: peer),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.read<MeshService>().start(),
        child: const Icon(Icons.wifi_find),
      ),
    );
  }
}

