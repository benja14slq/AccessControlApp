import 'package:accesscontrol/auth/login_page.dart';
import 'package:accesscontrol/resident/screens/family_page.dart';
import 'package:accesscontrol/resident/state/resident_state.dart';
import 'package:accesscontrol/state/app_state.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 

class SettingsPage extends StatelessWidget { 
  const SettingsPage({super.key, required this.state});
  final ResidentState state;

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      
      final appState = Provider.of<AppState>(context, listen: false);

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => LoginPage(appState: appState),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      // Manejar error
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, child) {
        
        // 2. Mostramos un 'loading' si el estado aún no carga el perfil
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Cuenta', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Column(children: [
                ListTile(
                  title: const Text('Correo'), 
                  // Usamos los datos del estado
                  trailing: Text(state.residentEmail)
                ),
                ListTile(
                  title: const Text('Unidad'), 
                  // Usamos los datos del estado
                  trailing: Text(state.condoUnit)
                ),
                const Divider(height: 0),
                ListTile(
                  title: const Text('Grupo Familiar'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: (){
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => FamilyPage(state: state), 
                    ));
                  },
                ),
                const Divider(height: 0),
                ListTile(
                  title: const Text('Biometria facial'),
                  trailing: Text(state.hasFaceId ? 'Registrada' : 'Registrar ahora'),
                  onTap: state.hasFaceId
                    ? null
                    : () async {
                      try {
                        await state.registerFaceId();
                        if (context.mounted){
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Rostro registrado con éxito.')),
                          );
                        }
                      } catch (e){
                        if (context.mounted){
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                ),
              ]),
            ),
            const SizedBox(height: 16),
            Text('Preferencias de acceso', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Column(children: [
                SwitchListTile(
                  title: const Text('Notificaciones por email'),
                  value: state.notifEmail, // Este valor ahora es 'bool'
                  // 3. Llamamos al método async directamente
                  onChanged: state.setNotifEmail,
                ),
                const Divider(height: 0),
                SwitchListTile(
                  title: const Text('Notificaciones push'),
                  value: state.notifPush, // Este valor ahora es 'bool'
                  // 3. Llamamos al método async directamente
                  onChanged: state.setNotifPush,
                ),
              ]),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => _logout(context), // Llama al logout real
              icon: const Icon(Icons.logout), 
              label: const Text('Cerrar Sesión'),
            ),
          ],
        );
      },
    );
  }
}