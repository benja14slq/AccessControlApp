import 'package:accesscontrol/admin/state/admin_state.dart';
import 'package:flutter/material.dart';

class AdminGuardsPage extends StatefulWidget {
  const AdminGuardsPage({super.key, required this.adminState});
  final AdminState adminState;

  @override
  State<AdminGuardsPage> createState() => _AdminGuardsPageState();
}

class _AdminGuardsPageState extends State<AdminGuardsPage> {
  
  void _showInviteDialog() {
    final emailCtrl = TextEditingController();
    final unitCtrl = TextEditingController();
    
    showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: const Text('Invitar Guardia'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: unitCtrl, decoration: const InputDecoration(labelText: 'Turno/Rol (Ej: Turno Noche)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              widget.adminState.inviteGuard(emailCtrl.text, unitCtrl.text);
              Navigator.of(ctx).pop();
            }, 
            child: const Text('Invitar')
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final guards = widget.adminState.users.where((u) => u.role == 'Guardia').toList();

    return Scaffold(
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: guards.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final user = guards[i];
          return Card(
            child: ListTile(
              title: Text(user.email),
              subtitle: Text(user.unit),
              trailing: Chip(
                label: Text(user.registered ? 'Registrado' : 'Pendiente', style: const TextStyle(fontSize: 12)),
                backgroundColor: user.registered ? Colors.green.shade50 : Colors.grey.shade200,
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showInviteDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}