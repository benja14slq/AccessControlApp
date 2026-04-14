import 'package:accesscontrol/state/app_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminGuardsPage extends StatefulWidget {
  const AdminGuardsPage({super.key, required this.appState});
  final AppState appState;

  @override
  State<AdminGuardsPage> createState() => _AdminGuardsPageState();
}

class _AdminGuardsPageState extends State<AdminGuardsPage> {
  
  final _emailCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();

  Future<void> _showInviteDialog() async {
    final adminState = widget.appState.adminState;
    if (adminState.isLoadingAdminData) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cargando datos del administrador...'))
      );
      return;
    }

    _emailCtrl.clear();
    _nombreCtrl.clear();
    _apellidoCtrl.clear();
    
    showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: const Text('Invitar Guardia'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _emailCtrl, 
                decoration: const InputDecoration(labelText: 'Email del Guardia'),
                keyboardType: TextInputType.emailAddress,
              ),
              TextField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre'),
                textCapitalization: TextCapitalization.words,
              ),
              TextField(
                controller: _apellidoCtrl,
                decoration: const InputDecoration(labelText: 'Apellido'),
                textCapitalization: TextCapitalization.words,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => _createPendingGuard(ctx), 
            child: const Text('Invitar')
          ),
        ],
      )
    );
  }

  Future<void> _createPendingGuard(BuildContext dialogContext) async {
    final email = _emailCtrl.text.trim();
    final nombre = _nombreCtrl.text.trim();
    final apellido = _apellidoCtrl.text.trim();
    
    // CAMBIO CLAVE: Obtenemos el condominioId desde el estado
    final condominioId = widget.appState.adminState.currentCondominioId;

    if (email.isEmpty || nombre.isEmpty || apellido.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Por favor, completa todos los campos.'))
      );
      return;
    }

    if (condominioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Error: No se ha detectado el condominio actual.'))
      );
      return;
    }

    try {
      final duplicateCheck = await FirebaseFirestore.instance
          .collection('Guardias')
          .where('correo', isEqualTo: email)
          .limit(1)
          .get();

      if (duplicateCheck.docs.isNotEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Este correo ya está registrado como guardia.'),
                  backgroundColor: Colors.orange,
                )
            );
          }
          return;
      }

      // CAMBIO CLAVE: Guardamos solo la estructura limpia de NoSQL
      final Map<String, dynamic> guardData = {
        'condominioId': condominioId, // Nueva relación
        'correo': email,
        'nombre': nombre,
        'apellido': apellido,
        'estado': 'Pendiente',
        'rol': 'Guardia',
        'createdAt': FieldValue.serverTimestamp(),
        'uid': null, 
      };

      await FirebaseFirestore.instance.collection('Guardias').add(guardData);
      
      if (dialogContext.mounted) {
        Navigator.of(dialogContext).pop(); 
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Guardia invitado con éxito.'))
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al invitar guardia: $e'))
        );
      }
    }
  }

  Future<void> _deleteGuard(String docId) async {
    final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
            title: const Text('¿Despedir Guardia?'),
            content: const Text('Esto eliminará su acceso al sistema permanentemente.'),
            actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
            ],
        )
    );

    if (confirm == true) {
        await FirebaseFirestore.instance.collection('Guardias').doc(docId).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final condominioId = widget.appState.adminState.currentCondominioId;

    if (condominioId == null) {
      return const Center(child: Text('Cargando condominio...'));
    }

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Guardias')
            .where('condominioId', isEqualTo: condominioId) // CAMBIO
            .orderBy('createdAt', descending: true)
            .snapshots(),
        
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Aún no has invitado guardias.'));
          }

          final guards = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: guards.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final data = guards[i].data() as Map<String, dynamic>;
              final String estado = data['estado'] ?? 'Pendiente';
              
              final String title = '${data['nombre']} ${data['apellido']}';

              return Card(
                child: ListTile(
                  title: Text(title),
                  subtitle: Text(data['correo'] ?? 'Sin email'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Chip(label: Text(estado)),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteGuard(guards[i].id),
                      )
                    ],
                  ),
                ),
              );
            },
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