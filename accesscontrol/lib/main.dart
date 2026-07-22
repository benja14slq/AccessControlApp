import 'package:accesscontrol/auth/login_page.dart';
import 'package:accesscontrol/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';

// 1. FUNCIÓN DE SEGUNDO PLANO (Debe estar obligatoriamente fuera de main y de cualquier clase)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Aseguramos que Firebase esté inicializado en este "hilo fantasma"
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Mensaje en segundo plano recibido: ${message.messageId}");
}

final AppState globalState = AppState();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 2. CONECTAR LA FUNCIÓN AL ESCUCHA DE FIREBASE
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 3. PEDIR PERMISOS AL USUARIO (Vital en Android 13+ y iOS)
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  runApp(
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
      home: LoginPage(appState: globalState),
    );
  }
}
