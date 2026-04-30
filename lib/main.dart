import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/mesh_service.dart';
import 'services/storage_service.dart';
import 'ui/screens/onboarding_screen.dart';
import 'models/message.dart';
import 'models/peer.dart';
import 'models/key_pair.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(MessageAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(PeerAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(KeyPairAdapter());
    }

    await Hive.openBox<Message>(kMessagesBox);
    await Hive.openBox<Peer>(kPeersBox);
    await Hive.openBox<dynamic>(kKeysBox);

    final storage = StorageService();
    await storage.init();
    final meshService = MeshService(storage);
    await meshService.init();

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: storage),
          ChangeNotifierProvider.value(value: meshService),
        ],
        child: const MeshChatApp(),
      ),
    );
  } catch (e, st) {
    debugPrint('FATAL INIT ERROR: $e\n$st');
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF121212),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Startup error:\n$e',
                style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MeshChatApp extends StatelessWidget {
  const MeshChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kAppName,
      theme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFF0A192F),
        scaffoldBackgroundColor: const Color(0xFF020C1B),
        textTheme: ThemeData.dark().textTheme.apply(
              fontFamily: 'Inter',
              bodyColor: const Color(0xFFE6F1FF),
              displayColor: const Color(0xFFE6F1FF),
            ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A192F),
          foregroundColor: Color(0xFFE6F1FF),
          elevation: 0,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF3A86FF),
          foregroundColor: Colors.white,
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF3A86FF),
          secondary: Color(0xFF00D1FF),
          surface: Color(0xFF112240),
          error: Color(0xFFFF4D4F),
        ),
      ),
      home: const OnboardingScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
