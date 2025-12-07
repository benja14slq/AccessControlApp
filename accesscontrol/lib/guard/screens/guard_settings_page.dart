import 'package:accesscontrol/auth/login_page.dart';
import 'package:accesscontrol/state/app_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:accesscontrol/guard/state/guard_state.dart';

class GuardSettingsPage extends StatelessWidget {
  const GuardSettingsPage({super.key});

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();

      final appState = Provider.of<AppState>(context, listen: false);
      if (context.mounted){
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => LoginPage(appState: appState),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cerrar sesión: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final guardState = context.watch<GuardState>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const CircleAvatar(radius: 40, child: Icon(Icons.security, size: 40)),
        const SizedBox(height: 16),
        Center(child: Text(guardState.guardFullName, style: Theme.of(context).textTheme.headlineSmall)),
        const SizedBox(height: 32),
        Card(
          child: Column(children: [
            ListTile(
              leading: const Icon(Icons.badge),
              title: const Text('Rol'),
              subtitle: const Text('Guardia de Seguridad'),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Cerrar sesión'),
              onTap: () => _logout(context),
            ),
          ])
        )
      ],
    );
  }
}