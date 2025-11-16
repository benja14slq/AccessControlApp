import 'package:accesscontrol/resident/state/resident_state.dart';
import 'package:flutter/material.dart';

class FamilyPage extends StatefulWidget {
  const FamilyPage({super.key, required this.state});
  final ResidentState state;

  @override
  State<FamilyPage> createState() => _FamilyPageState();
}

class _FamilyPageState extends State<FamilyPage> {
  final _nameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _rutCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _lastNameCtrl.dispose();
    _rutCtrl.dispose();
    super.dispose();
  }

  void _showAddMemberDialog(){
    _nameCtrl.clear();
    _lastNameCtrl.clear();
    _rutCtrl.clear();

    showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: const Text('Agregar Miembro Familiar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
            TextField(controller: _lastNameCtrl, decoration: const InputDecoration(labelText: 'Apellido')),
            TextField(controller: _rutCtrl, decoration: const InputDecoration(labelText: 'RUT')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              if (_nameCtrl.text.isEmpty || _lastNameCtrl.text.isEmpty) return;
              try{
                await widget.state.addFamilyMember(
                  nombre: _nameCtrl.text.trim(), 
                  apellido: _lastNameCtrl.text.trim(),
                  rut: _rutCtrl.text.trim().isEmpty ? null : _rutCtrl.text.trim(),
                );
                if (mounted) Navigator.of(ctx).pop();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
                  );
                }
              }
            }, 
            child: const Text('Agregar'),
          )
        ],
      )
    );
  }

  Future<void> _registerFace(String memberId) async {
    try {
      await widget.state.registerFamilyMemberFace(memberId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rostro registrado con éxito.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Grupo Familiar')),
      body: AnimatedBuilder(
        animation: widget.state,
        builder: (context, child) {
          if (widget.state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (widget.state.familyMembers.isEmpty) {
            return const Center(child: Text('Aún no has agregado miembros.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: widget.state.familyMembers.length,
            itemBuilder: (context, index) {
              final member = widget.state.familyMembers[index];
              return Card(
                child: ListTile(
                  title: Text('${member.nombre} ${member.apellido}'),
                  subtitle: Text(member.rut ?? 'Sin RUT'),
                  trailing: member.hasFaceId
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : TextButton(
                          onPressed: () => _registerFace(member.id),
                          child: const Text('Registrar rostro'),
                        ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMemberDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}