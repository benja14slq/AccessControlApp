import 'package:accesscontrol/admin/state/admin_state.dart';
import 'package:accesscontrol/auth/login_page.dart';
import 'package:accesscontrol/state/app_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdminSettingsPage extends StatelessWidget {
  const AdminSettingsPage({super.key, required this.appState});
  final AppState appState;

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();

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
          SnackBar(content: Text('Error al cerrar sesión: ${e.toString()}'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminState>(
      builder: (context, adminState, child) {
        final biometricsEnabled = adminState.condoConfig['biometricsEnabled'] ?? true;
        final lprEnabled = adminState.condoConfig['lprEnabled'] ?? true;
        final unannouncedVisitsEnabled = adminState.condoConfig['unannouncedVisitsEnabled'] ?? true;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Mi Cuenta', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const SizedBox(height: 8),
            Text('Módulos del Condominio', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Biometría Facial'),
                    subtitle: const Text('Permitir registro y acceso por rostro'),
                    value: biometricsEnabled, 
                    onChanged: (value) {
                      adminState.updateConfig('biometricsEnabled', value);
                    },
                  ),
                  const Divider(height: 0, indent: 16, endIndent: 16),
                  SwitchListTile(
                    title: const Text('Acceso Vehicular (LPR)'),
                    subtitle: const Text('Permitir escaneo de patentes.'),
                    value: lprEnabled,
                    onChanged: (value) {
                      adminState.updateConfig('lprEnabled', value);
                    },
                  ),
                  const Divider(height: 0, indent: 16, endIndent: 16),
                  SwitchListTile(
                    title: const Text('Visitas No Anunciadas'),
                    subtitle: const Text('Permitir al guardia notificar visitas.'),
                    value: unannouncedVisitsEnabled,
                    onChanged: (value) {
                      adminState.updateConfig('unannouncedVisitsEnabled', value);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Cerrar Sesión'),
                onTap: () => _logout(context),
              ),
            )
          ],
        );
      }
    );
  }
}