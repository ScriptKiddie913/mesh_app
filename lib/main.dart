import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'models/message.dart';
import 'models/peer.dart';
import 'models/key_pair.dart';
import 'models/identity.dart';
import 'services/storage_service.dart';
import 'services/mesh_service.dart';
import 'ui/screens/onboarding_screen.dart';
import 'utils/theme.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Hive.initFlutter();
    
    // Register Adapters
    Hive.registerAdapter(MessageAdapter());
    Hive.registerAdapter(PeerAdapter());
    Hive.registerAdapter(KeyPairAdapter());
    Hive.registerAdapter(NodeIdentityAdapter());
    
    // Open Boxes with proper types
    await Hive.openBox<Message>(kMessagesBox);
    await Hive.openBox<Peer>(kPeersBox);
    await Hive.openBox<dynamic>(kKeysBox);
    await Hive.openBox<NodeIdentity>('identities');

    final storage = StorageService();
    await storage.init();

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: storage),
          ChangeNotifierProvider(create: (_) => MeshService(storage)..init()),
        ],
        child: const MeshApp(),
      ),
    );
  } catch (e) {
    debugPrint('CRITICAL BOOT ERROR: $e');
    // Emergency cleanup for "Null is not subtype of int" on some phones
    try {
      await Hive.deleteBoxFromDisk(kMessagesBox);
      await Hive.deleteBoxFromDisk(kPeersBox);
    } catch (_) {}
    
    runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 80),
              const SizedBox(height: 24),
              const Text('SYSTEM RECOVERY ACTIVE', style: TextStyle(color: Colors.white, fontFamily: MeshTheme.fontMono, fontSize: 18)),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Initialization failed due to data incompatibility. Database has been reset. Please restart the application.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}

class MeshApp extends StatelessWidget {
  const MeshApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: MeshTheme.bg0,
        colorScheme: const ColorScheme.dark(
          primary: MeshTheme.accent,
          surface: MeshTheme.bg1,
        ),
        useMaterial3: true,
      ),
      home: const OnboardingScreen(),
    );
  }
}
