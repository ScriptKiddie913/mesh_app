import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/mesh_service.dart';
import '../../utils/constants.dart';
import '../widgets/radar_animation.dart';
import 'chat_screen.dart';
import 'map_screen.dart';

class PeersScreen extends StatefulWidget {
  const PeersScreen({super.key});

  @override
  State<PeersScreen> createState() => _PeersScreenState();
}

class _PeersScreenState extends State<PeersScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-start scanning when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mesh = context.read<MeshService>();
      if (!mesh.isRunning) {
        mesh.start();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.hub_outlined, color: Color(0xFF00D1FF), size: 20),
            SizedBox(width: 8),
            Text(
              'SoTaNIk_AI Mesh',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                letterSpacing: 2.0,
                fontSize: 18,
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
            icon: const Icon(Icons.map_outlined, color: Color(0xFFE6F1FF)),
            tooltip: 'Tactical Map',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MapScreen()),
              );
            },
          ),
          Consumer<MeshService>(
            builder: (context, mesh, _) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (mesh.isScanning)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: Color(0xFF00D1FF),
                        ),
                      ),
                    ),
                  IconButton(
                    icon: Icon(
                      mesh.isRunning ? Icons.refresh : Icons.play_arrow,
                      color: const Color(0xFFE6F1FF),
                    ),
                    onPressed: () => mesh.start(),
                    tooltip: mesh.isRunning ? 'RESCAN SECTOR' : 'INITIATE SCAN',
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<MeshService>(
        builder: (context, mesh, child) {
          // Show error if any
          if (mesh.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 64, color: Color(0xFFFF4D4F)),
                    const SizedBox(height: 16),
                    Text(
                      mesh.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFFFF4D4F)),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => mesh.start(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('RETRY UPLINK', style: TextStyle(letterSpacing: 1.2)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF112240),
                        foregroundColor: const Color(0xFFFF4D4F),
                        side: const BorderSide(color: Color(0xFFFF4D4F)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final peers = mesh.peers;

          // Empty state
          if (peers.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (mesh.isScanning)
                      const RadarAnimation(size: 160)
                    else
                      Icon(
                        Icons.sensors_off,
                        size: 80,
                        color: const Color(0xFF3A86FF).withValues(alpha: 0.5),
                      ),
                    const SizedBox(height: 48),
                    Text(
                      mesh.isScanning
                          ? 'Scanning for nearby devices...'
                          : 'NO SIGNALS DETECTED',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w300,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      mesh.isScanning
                          ? 'Ensure nearby nodes have TACOPS active with Bluetooth enabled'
                          : 'Tap scan to locate active operatives',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF8892B0),
                        fontSize: 12,
                      ),
                    ),
                    if (!mesh.isRunning) ...[
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: () => mesh.start(),
                        icon: const Icon(Icons.radar),
                        label: const Text('INITIATE SWEEP', style: TextStyle(letterSpacing: 1.5)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF112240),
                          foregroundColor: const Color(0xFF00D1FF),
                          side: const BorderSide(color: Color(0xFF3A86FF)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }

          // Peer list
          return ListView.builder(
            itemCount: peers.length,
            padding: const EdgeInsets.only(top: 16),
            itemBuilder: (context, i) {
              final peer = peers[i];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF112240).withValues(alpha: 0.7),
                  border: Border.all(color: const Color(0xFF3A86FF).withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (peer.connected)
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00D1FF).withValues(alpha: 0.4),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                      CircleAvatar(
                        backgroundColor: const Color(0xFF020C1B),
                        child: Text(
                          peer.username.isNotEmpty
                              ? peer.username[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: peer.connected ? const Color(0xFF00D1FF) : const Color(0xFF8892B0),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  title: Text(
                    peer.username.toUpperCase(),
                    style: const TextStyle(
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    peer.connected ? 'UPLINK ESTABLISHED' : 'SIGNAL DETECTED',
                    style: TextStyle(
                      color: peer.connected ? const Color(0xFF00D1FF) : const Color(0xFF8892B0),
                      fontSize: 10,
                      letterSpacing: 1.0,
                    ),
                  ),
                  trailing: peer.connected
                      ? const Icon(Icons.check_circle_outline, color: Color(0xFF00D1FF))
                      : TextButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('ESTABLISHING LINK TO ${peer.username.toUpperCase()}...'),
                                backgroundColor: const Color(0xFF112240),
                              ),
                            );
                            context.read<MeshService>().connectToPeer(peer);
                          },
                          icon: const Icon(Icons.link, size: 16),
                          label: const Text('CONNECT', style: TextStyle(letterSpacing: 1.0)),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF3A86FF),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
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
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF3A86FF), Color(0xFF00D1FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00D1FF).withValues(alpha: 0.4),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => context.read<MeshService>().start(),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.radar, color: Colors.white),
        ),
      ),
    );
  }
}
