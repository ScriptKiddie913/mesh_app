import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import '../../services/storage_service.dart';
import '../../services/mesh_service.dart';
import '../../services/crypto_service.dart';
import '../../models/key_pair.dart';
import '../../utils/constants.dart';
import 'peers_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _usernameController = TextEditingController();
  bool _loading = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _checkExistingUser();
  }

  Future<void> _checkExistingUser() async {
    final storage = context.read<StorageService>();
    final username = storage.getUsername();
    if (username != null && username.isNotEmpty) {
      // Already onboarded — go to peers
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const PeersScreen()),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00D1FF).withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/images/logo.jpg',
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => 
                        const Icon(Icons.security, size: 80, color: Color(0xFF00D1FF)),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'SoTaNIk_AI Mesh',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.0,
                  color: const Color(0xFFE6F1FF),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'SECURE DECENTRALIZED MESH COMMUNICATION\nOFFLINE CAPABLE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF8892B0),
                  letterSpacing: 1.2,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'OPERATIVE ID',
                  labelStyle: const TextStyle(color: Color(0xFF8892B0), letterSpacing: 1.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF3A86FF)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF112240)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF00D1FF)),
                  ),
                  prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF00D1FF)),
                  filled: true,
                  fillColor: const Color(0xFF112240).withValues(alpha: 0.5),
                ),
                enabled: !_loading,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _completeOnboarding,
                  icon: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Color(0xFF00D1FF), strokeWidth: 2))
                      : const Icon(Icons.login),
                  label: Text(
                    _loading ? 'INITIALIZING...' : 'START TACCOM',
                    style: const TextStyle(letterSpacing: 1.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF112240),
                    foregroundColor: const Color(0xFF00D1FF),
                    side: const BorderSide(color: Color(0xFF3A86FF)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              if (_status != null) ...[
                const SizedBox(height: 12),
                Text(_status!,
                    style: const TextStyle(
                        color: Color(0xFF00D1FF), fontSize: 13, letterSpacing: 1.1)),
              ],
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _loading ? null : _requestPermissions,
                icon: const Icon(Icons.security),
                label:
                    const Text('AUTHORIZE SYSTEM ACCESS', style: TextStyle(letterSpacing: 1.2)),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF8892B0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _completeOnboarding() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a username')),
      );
      return;
    }

    setState(() {
      _loading = true;
      _status = 'Requesting permissions...';
    });

    try {
      await _requestPermissions();

      if (!mounted) return;
      setState(() => _status = 'Generating encryption keys...');

      // Run RSA key generation in a background isolate to avoid UI freeze
      final rawKeys = await compute(CryptoService.generateKeyPairRaw, null);
      final keyPair = KeyPair(
        privateKey: rawKeys['private']!,
        publicKey: rawKeys['public']!,
      );

      if (!mounted) return;
      setState(() => _status = 'Saving profile...');

      final storage = Provider.of<StorageService>(context, listen: false);
      final deviceId = const Uuid().v4();
      await storage.saveUsername(username);
      await storage.saveKeyPair(keyPair, deviceId);

      if (!mounted) return;

      // Auto-start mesh service
      final mesh = context.read<MeshService>();
      await mesh.start();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PeersScreen()),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _status = 'Error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.location,
      Permission.locationWhenInUse,
      Permission.nearbyWifiDevices,
    ].request();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permissions requested')),
      );
    }
  }
}
