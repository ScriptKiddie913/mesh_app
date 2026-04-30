import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import '../../services/storage_service.dart';
import '../../services/crypto_service.dart';
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

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_tethering, size: 80, color: Colors.orange),
            const SizedBox(height: 32),
            Text(kAppName, style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 16),
            const Text('Offline mesh chat via Bluetooth & WiFi', 
                 textAlign: TextAlign.center),
            const SizedBox(height: 48),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Choose username',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _completeOnboarding,
              child: _loading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Start Mesh Chat'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _requestPermissions,
              child: const Text('Grant Permissions (Bluetooth, Location)'),
            ),
          ],
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

    setState(() => _loading = true);

    try {
      // Use Provider to get StorageService
      final storage = Provider.of<StorageService>(context, listen: false);
      final keyPair = CryptoService.generateKeyPair();
      final deviceId = Uuid().v4();

      await storage.saveUsername(username);
      await storage.saveKeyPair(keyPair, deviceId);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PeersScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _requestPermissions() async {
    // Request multiple permissions
    final bluetooth = await Permission.bluetooth.request();
    final bluetoothScan = await Permission.bluetoothScan.request();
    final bluetoothAdvertise = await Permission.bluetoothAdvertise.request();
    final location = await Permission.location.request();
    final locationWhenInUse = await Permission.locationWhenInUse.request();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Bluetooth: $bluetooth, '
            'Scan: $bluetoothScan, '
            'Advertise: $bluetoothAdvertise, '
            'Location: $location, '
            'LocationWhenInUse: $locationWhenInUse'
          ),
        ),
      );
    }
  }
}
