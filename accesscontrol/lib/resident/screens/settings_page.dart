import 'package:accesscontrol/resident/state/resident_state.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.state});
  final ResidentState state;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Cuenta', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Column(children: [
            ListTile(title: const Text('Correo'), trailing: Text(widget.state.residentEmail)),
            const Divider(height: 0),
            ListTile(
              title: const Text('Biometria facial'),
              trailing: Text(widget.state.hasFaceId ? 'Registrada' : 'Pendiente'),
              onTap: () => setState(widget.state.toggleFaceId),
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
              value: widget.state.notifEmail, 
              onChanged: (v) => setState (() => widget.state.setNotifEmail(v)),
            ),
            const Divider(height: 0),
            SwitchListTile(
              title: const Text('Notificaciones push'),
              value: widget.state.notifPush,
              onChanged: (v) => setState(() => widget.state.setNotifPush(v)),
            ),
          ]),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cerrar sesión (demo)'))),
          icon: const Icon(Icons.logout), 
          label: const Text('Cerrar Sesión'),
        ),
      ],
    );
  }
}