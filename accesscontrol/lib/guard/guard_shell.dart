import 'package:accesscontrol/guard/screens/guard_events_page.dart';
import 'package:accesscontrol/guard/screens/guard_manual_page.dart';
import 'package:accesscontrol/guard/screens/guard_settings_page.dart';
import 'package:accesscontrol/guard/screens/guard_verify_page.dart';
import 'package:accesscontrol/guard/state/guard_state.dart';
import 'package:flutter/material.dart';

class GuardShell extends StatefulWidget {
  const GuardShell({super.key, required this.guardState});
  final GuardState guardState;

  @override
  State<GuardShell> createState() => _GuardShellState();
}

class _GuardShellState extends State<GuardShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      GuardVerifyPage(state: widget.guardState), // Pantalla para escanear/teclear código
      GuardEventsPage(state: widget.guardState), // Bitácora de eventos
      GuardManualPage(state: widget.guardState), // Botones para abrir barreras
      const GuardSettingsPage(),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Conserjería — Guardia')),
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.qr_code_scanner), selectedIcon: Icon(Icons.qr_code_scanner_rounded), label: 'Verificar'),
          NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: 'Bitácora'),
          NavigationDestination(icon: Icon(Icons.key_outlined), selectedIcon: Icon(Icons.key), label: 'Manual'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Cuenta'),
        ],
      ),
    );
  }
}