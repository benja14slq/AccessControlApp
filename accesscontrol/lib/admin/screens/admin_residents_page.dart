import 'package:accesscontrol/admin/state/admin_state.dart';
import 'package:flutter/material.dart';

class AdminResidentsPage extends StatefulWidget {
  const AdminResidentsPage({super.key, required this.adminState});
  final AdminState adminState;

  @override
  State<AdminResidentsPage> createState() => _AdminResidentsPageState();
}

class _AdminResidentsPageState extends State<AdminResidentsPage> {
  
  void _showInviteDialog() {
    final emailCtrl = TextEditingController();
    final unitCtrl = TextEditingController();
    
    showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: const Text('Invitar Residente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: unitCtrl, decoration: const InputDecoration(labelText: 'Unidad (Ej: Depto 101)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              widget.adminState.inviteResident(emailCtrl.text, unitCtrl.text);
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
    final residents = widget.adminState.users.where((u) => u.role == 'Residente').toList();

    return Scaffold(
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: residents.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final user = residents[i];
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