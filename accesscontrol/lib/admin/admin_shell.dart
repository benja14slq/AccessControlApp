import 'package:accesscontrol/admin/screens/admin_dashboard_page.dart';
import 'package:accesscontrol/admin/screens/admin_guards_page.dart';
import 'package:accesscontrol/admin/screens/admin_logbook_page.dart';
import 'package:accesscontrol/admin/screens/admin_residents_page.dart';
import 'package:accesscontrol/admin/screens/admin_settings_page.dart';
import 'package:accesscontrol/state/app_state.dart';
import 'package:flutter/material.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key, required this.appState});
  final AppState appState;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int index = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      AdminDashboardPage(appState: widget.appState), 
      AdminResidentsPage(appState: widget.appState),
      AdminGuardsPage(appState: widget.appState),
      AdminLogbookPage(appState: widget.appState), 
      AdminSettingsPage(appState: widget.appState),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Condominio — Admin')),
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Residentes'),
          NavigationDestination(icon: Icon(Icons.security_outlined), selectedIcon: Icon(Icons.security), label: 'Guardias'),
          NavigationDestination(icon: Icon(Icons.book_outlined), selectedIcon: Icon(Icons.book), label: 'Bitácora'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Cuenta'),
        ],
      ),
    );
  }
}