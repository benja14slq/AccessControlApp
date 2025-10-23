import 'package:accesscontrol/state/app_state.dart';
import 'package:accesscontrol/visit/screens/visit_pass_page.dart';
import 'package:flutter/material.dart';

class VisitApp extends StatelessWidget {
  const VisitApp({super.key, required this.appState});
  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Condominio — Visita',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.orange,
        brightness: Brightness.light,
      ),
      // La app de visita solo tiene una pantalla, 
      // le pasamos el estado del residente para que "encuentre" el pase
      home: VisitPassPage(residentState: appState.residentState),
    );
  }
}