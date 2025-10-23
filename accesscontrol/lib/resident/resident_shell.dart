import 'package:accesscontrol/resident/screens/create_pass_page.dart';
import 'package:accesscontrol/resident/screens/home_page.dart';
import 'package:accesscontrol/resident/screens/my_visits_page.dart';
import 'package:accesscontrol/resident/screens/settings_page.dart';
import 'package:accesscontrol/resident/screens/vehicles_page.dart';
import 'package:accesscontrol/resident/state/resident_state.dart';
import 'package:flutter/material.dart';

class ResidentShell extends StatefulWidget {
  const ResidentShell({super.key, required this.residentState});
  final ResidentState residentState;

  @override
  State<ResidentShell> createState() => _ResidentShellState();
}

class _ResidentShellState extends State<ResidentShell> {
  int index = 0; // 0: Home, 1: Crear, 2: Visitas, 3: Vehículos, 4: Cuenta

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        state: widget.residentState,
        goToCreate: () => setState(() => index = 1),
        goToVisits: () => setState(() => index = 2),
      ),
      CreatePassPage(state: widget.residentState, onCreated: () => setState(() => index = 2)),
      MyVisitsPage(state: widget.residentState),
      VehiclesPage(state: widget.residentState),
      SettingsPage(state: widget.residentState),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Condominio — Residente')),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: pages[index],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.qr_code_2_outlined), selectedIcon: Icon(Icons.qr_code_2), label: 'Generar'),
          NavigationDestination(icon: Icon(Icons.list_alt_outlined), selectedIcon: Icon(Icons.list_alt), label: 'Visitas'),
          NavigationDestination(icon: Icon(Icons.directions_car_outlined), selectedIcon: Icon(Icons.directions_car), label: 'Vehículos'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Cuenta'),
        ],
      ),
    );
  }
}