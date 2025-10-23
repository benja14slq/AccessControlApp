import 'package:accesscontrol/resident/resident_shell.dart';
import 'package:accesscontrol/state/app_state.dart';
import 'package:flutter/material.dart';

// Esta es la App del Residente
class ResidentApp extends StatelessWidget {
  const ResidentApp({super.key, required this.appState});
  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Condominio — Residente',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
      ),
      // Pasamos el estado del residente al Shell
      home: ResidentShell(residentState: appState.residentState),
    );
  }
}