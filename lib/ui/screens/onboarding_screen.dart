import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/storage_service.dart';
import '../../services/mesh_service.dart';
import '../../services/crypto_service.dart';
import 'peers_screen.dart';
import '../../utils/theme.dart';
import '../widgets/mesh_widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkExistingUser());
  }

Future<void> _checkExistingUser() async {
    final storage = context.read<StorageService>();
    final username = storage.getUsername();
    
    if (username != null) {
      // Check if keypair exists, generate if not (now synchronous)
      final keyPair = storage.getKeyPair();
      if (keyPair == null) {
        final newKeyPair = CryptoService.generateKeyPair();
        await storage.saveKeyPair(newKeyPair);
      }
      
      await _requestPermissions();
      final mesh = context.read<MeshService>();
      await mesh.start();
      _navigateToPeers();
    }
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.location,
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.nearbyWifiDevices,
    ].request();
  }

  void _navigateToPeers() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const PeersScreen()),
    );
  }

Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _isSaving = true);
    
    try {
      final storage = context.read<StorageService>();
      await storage.saveUsername(_nameController.text.trim());
      
      // Generate keypair for encryption and mesh messaging
      final keyPair = CryptoService.generateKeyPair();
      await storage.saveKeyPair(keyPair);
      
      final mesh = context.read<MeshService>();
      await mesh.start();
      
      _navigateToPeers();
    } catch (e) {
      debugPrint('Profile save error: $e');
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MeshTheme.bg0,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(MeshTheme.s6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: MeshTheme.s10),
              TacticalCard(
                borderColor: MeshTheme.accent,
                tag: 'LOGO',
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      height: 120,
                      errorBuilder: (context, error, stackTrace) => 
                          const Icon(Icons.security, size: 80, color: MeshTheme.accent),
                    ),
                    const SizedBox(height: MeshTheme.s4),
                    const Text(
                      'soTaNik_AI Mesh CHAT',
                      style: TextStyle(
                        fontFamily: MeshTheme.fontMono,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                        color: MeshTheme.accent,
                      ),
                    ),
                    const StatusBadge(label: 'READY', color: MeshTheme.accentG, blink: true),
                  ],
                ),
              ),
              const SizedBox(height: MeshTheme.s8),
              const SectionDivider('SYSTEM INITIALIZATION'),
              const SizedBox(height: MeshTheme.s4),
              const Text(
                'ENTER OPERATOR DESIGNATION TO LINK WITH DECENTRALIZED NETWORK',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: MeshTheme.textSec, height: 1.5),
              ),
              const SizedBox(height: MeshTheme.s6),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: MeshTheme.textPri, fontFamily: MeshTheme.fontMono),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: MeshTheme.bg1,
                  hintText: 'CODENAME...',
                  hintStyle: const TextStyle(color: MeshTheme.textDim),
                  border: const OutlineInputBorder(borderRadius: MeshTheme.sharp, borderSide: BorderSide(color: MeshTheme.border)),
                  enabledBorder: const OutlineInputBorder(borderRadius: MeshTheme.sharp, borderSide: BorderSide(color: MeshTheme.border)),
                  focusedBorder: const OutlineInputBorder(borderRadius: MeshTheme.sharp, borderSide: BorderSide(color: MeshTheme.accent)),
                ),
              ),
              const SizedBox(height: MeshTheme.s8),
              _isSaving 
                ? const CircularProgressIndicator(color: MeshTheme.accent)
                : TacticalButton(
                    label: 'INITIALIZE LINK',
                    onTap: _saveProfile,
                    filled: true,
                    icon: Icons.power_settings_new,
                  ),
              const SizedBox(height: MeshTheme.s10),
              const Text(
                'ENCRYPTION: RSA-2048 / AES-256 GCM\nPROTO: GOOGLE NEARBY P2P\nAUTONOMOUS RELAY ENABLED',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: MeshTheme.fontMono, fontSize: 10, color: MeshTheme.textDim),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
