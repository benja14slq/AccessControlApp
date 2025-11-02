// lib/main.dart
import 'package:accesscontrol/auth/login_page.dart';
import 'package:accesscontrol/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart'; // <-- 1. Importa Provider

final AppState globalState = AppState();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(
    // 2. Envuelve tu app en un ChangeNotifierProvider
    ChangeNotifierProvider(
      create: (context) => globalState,
      child: const RoleApp(),
    ),
  );
}

class RoleApp extends StatelessWidget {
  const RoleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
      ),
      // 3. Pasa el estado al LoginPage
      home: LoginPage(appState: globalState),
    );
  }
}