import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'services/mesh_service.dart';
import 'services/storage_service.dart';
import 'ui/screens/onboarding_screen.dart';
import 'models/message.dart';
import 'models/peer.dart';
import 'models/key_pair.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Init Hive
  final dir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(dir.path);
  Hive.registerAdapter(MessageAdapter());
  Hive.registerAdapter(PeerAdapter());
  Hive.registerAdapter(KeyPairAdapter());
  await Hive.openBox(kMessagesBox);
  await Hive.openBox(kPeersBox);
  await Hive.openBox(kKeysBox);

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
}

class MeshChatApp extends StatelessWidget {
  const MeshChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kAppName,
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.orange,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1f1f1f),
          foregroundColor: Colors.white,
        ),
      ),
      home: const OnboardingScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
