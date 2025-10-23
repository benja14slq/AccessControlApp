import 'package:accesscontrol/guard/guard_shell.dart';
import 'package:accesscontrol/state/app_state.dart';
import 'package:flutter/material.dart';

class GuardApp extends StatelessWidget {
  const GuardApp({super.key, required this.appState});
  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Condominio — Guardia',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blueGrey,
        brightness: Brightness.light,
      ),
      home: GuardShell(guardState: appState.guardState),
    );
  }
}