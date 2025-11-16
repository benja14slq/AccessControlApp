import 'package:accesscontrol/auth/login_page.dart';
import 'package:accesscontrol/state/app_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Cuenta de Guardia', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Cerrar sesión'),
            onTap: () => _logout(context),
          ),
        )
      ],
    );
  }
}