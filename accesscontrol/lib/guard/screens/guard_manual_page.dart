import 'package:accesscontrol/guard/state/guard_state.dart';
import 'package:flutter/material.dart';

class GuardManualPage extends StatelessWidget {
  const GuardManualPage({super.key, required this.state});
  final GuardState state;

  void _open(BuildContext context, String gate) {
    state.triggerManualAccess(gate);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Accionando: $gate')));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Acceso Peatonal', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.directions_walk),
            title: const Text('Abrir Puerta Principal'),
            trailing: const Icon(Icons.key),
            onTap: () => _open(context, 'Puerta Principal'),
          ),
        ),
        const SizedBox(height: 16),
        Text('Acceso Vehicular', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.directions_car),
            title: const Text('Abrir Barrera Entrada'),
            trailing: const Icon(Icons.key),
            onTap: () => _open(context, 'Barrera Entrada'),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.directions_car),
            title: const Text('Abrir Barrera Salida'),
            trailing: const Icon(Icons.key),
            onTap: () => _open(context, 'Barrera Salida'),
          ),
        ),
      ],
    );
  }
}