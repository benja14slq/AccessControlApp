import 'package:accesscontrol/resident/screens/create_pass_page.dart';
import 'package:accesscontrol/resident/screens/home_page.dart';
import 'package:accesscontrol/resident/screens/my_visits_page.dart';
import 'package:accesscontrol/resident/screens/settings_page.dart';
import 'package:accesscontrol/resident/screens/vehicles_page.dart';
import 'package:accesscontrol/resident/state/resident_state.dart';
import 'package:accesscontrol/resident/screens/notifications_page.dart';
import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    return ChangeNotifierProvider.value(
      value: widget.residentState,
      child: Builder(
        builder: (context) {
          final residentState = context.watch<ResidentState>();
          
          final pages = [
            HomePage(
              state: residentState, 
              goToCreate: () => setState(() => index = 1),
              goToVisits: () => setState(() => index = 2),
              goToSettings: () => setState(() => index = 4),
            ),
            CreatePassPage(state: residentState, onCreated: () => setState(() => index = 2)),
            MyVisitsPage(state: residentState),
            VehiclesPage(state: residentState),
            SettingsPage(state: residentState),
          ];

          return Scaffold(
            appBar: AppBar(
              title: const Text('Mi Condominio — Residente'),
              actions: [
                badges.Badge(
                  position: badges.BadgePosition.topEnd(top: 4, end: 4),
                  showBadge: residentState.pendingNotifications.isNotEmpty,
                  badgeContent: Text(
                    residentState.pendingNotifications.length.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider.value(
                          value: residentState,
                          child: const NotificationsPage(),
                        ),
                      ));
                    },
                  ),
                ),
                const SizedBox(width: 8)
              ],
            ),
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
      ),
    );
  }
}