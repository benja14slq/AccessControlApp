import 'package:accesscontrol/screens/create_pass_page.dart';
import 'package:accesscontrol/screens/my_visits_page.dart';
import 'package:accesscontrol/screens/settings_page.dart';
import 'package:accesscontrol/screens/vehicles_page.dart';
import 'package:flutter/material.dart';
import 'state/resident_state.dart';
import 'screens/home_page.dart';

void main() {
  runApp(const ResidentApp());
}

class ResidentApp extends StatelessWidget {
  const ResidentApp({super.key});

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
      home: const ResidentShell(),
    );
  }
}

class ResidentShell extends StatefulWidget {
  const ResidentShell({super.key});
  @override
  State<ResidentShell> createState() => _ResidentShellState();
}

class _ResidentShellState extends State<ResidentShell> {
  final ResidentState state = ResidentState();
  int index = 0; // 0: Home, 1: Crear, 2: Visitas, 3: Vehículos, 4: Cuenta

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        state: state,
        goToCreate: () => setState(() => index = 1),
        goToVisits: () => setState(() => index = 2),
      ),
      CreatePassPage(state: state, onCreated: () => setState(() => index = 2)),
      MyVisitsPage(state: state),
      VehiclesPage(state: state),
      SettingsPage(state: state),
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
