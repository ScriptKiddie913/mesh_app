import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/mesh_service.dart';
import 'chat_screen.dart';
import 'map_screen.dart';
import '../../utils/theme.dart';
import '../widgets/mesh_widgets.dart';
import '../../models/enums.dart';

class PeersScreen extends StatelessWidget {
  const PeersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mesh = context.watch<MeshService>();
    final peers = mesh.peers;

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
                  const Icon(Icons.hub_outlined, color: MeshTheme.accent, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'SoTaNik_AI Mesh',
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
                    icon: const Icon(Icons.map_outlined, color: Colors.white70, size: 24),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MapScreen()),
                    ),
                  ),
                  const Icon(Icons.blur_on, color: MeshTheme.accent, size: 22),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white70, size: 24),
                    onPressed: () => mesh.start(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: TacticalOverlay(
        child: Stack(
          children: [
            if (peers.isEmpty)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _CentralPulse(),
                    const SizedBox(height: 60),
                    const Text(
                      'Scanning for nearby devices...',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'Ensure nearby nodes have TACOPS active with Bluetooth enabled',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white38, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                padding: const EdgeInsets.only(top: 16, bottom: 100),
                itemCount: peers.length,
                itemBuilder: (context, i) {
                  final peer = peers[i];
                  return PeerTile(
                    peer: peer,
                    index: i + 1,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ChatScreen(peer: peer)),
                    ),
                  );
                },
              ),
            Positioned(
              bottom: 30,
              right: 20,
              child: _PulseFAB(onTap: () => mesh.start()),
            ),
          ],
        ),
      ),
    );
  }
}

class _CentralPulse extends StatefulWidget {
  const _CentralPulse();
  @override
  State<_CentralPulse> createState() => _CentralPulseState();
}

class _CentralPulseState extends State<_CentralPulse> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: MeshTheme.accent.withOpacity(1 - _ctrl.value), width: 2),
          ),
          child: Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: MeshTheme.accent.withOpacity(0.5), width: 1),
                gradient: RadialGradient(
                  colors: [MeshTheme.accent.withOpacity(0.2), Colors.transparent],
                ),
              ),
              child: const Icon(Icons.sensors, color: MeshTheme.accent, size: 40),
            ),
          ),
        );
      },
    );
  }
}

class _PulseFAB extends StatelessWidget {
  final VoidCallback onTap;
  const _PulseFAB({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 65,
        height: 65,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [MeshTheme.accent.withOpacity(0.8), Colors.blue.withOpacity(0.5)],
          ),
          boxShadow: [
            BoxShadow(color: MeshTheme.accent.withOpacity(0.3), blurRadius: 15, spreadRadius: 2),
          ],
        ),
        child: const Icon(Icons.center_focus_strong, color: Colors.white, size: 28),
      ),
    );
  }
}
