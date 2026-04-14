import 'package:accesscontrol/state/app_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminResidentsPage extends StatefulWidget {
  const AdminResidentsPage({super.key, required this.appState});
  final AppState appState;

  @override
  State<AdminResidentsPage> createState() => _AdminResidentsPageState();
}

class _AdminResidentsPageState extends State<AdminResidentsPage> {
  final _emailCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _torreCtrl = TextEditingController();
  final _numeroCtrl = TextEditingController();
  
  String _findCondoTypeName() {
    try {
      return widget.appState.condoTypes
          .firstWhere((t) => t.id == widget.appState.adminState.adminCondoTypeId)
          .name;
    } catch (e) {
      return '';
    }
  }

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
    _torreCtrl.clear();
    _numeroCtrl.clear();

    final condoTypeName = _findCondoTypeName();
    final bool isEdificio = condoTypeName.toLowerCase().contains('edificios');
    
    showDialog(
      context: context, 
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Invitar Residente'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _emailCtrl, 
                  decoration: const InputDecoration(labelText: 'Email del Residente'),
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
                
                if (isEdificio)
                  TextField(
                    controller: _torreCtrl, 
                    decoration: const InputDecoration(labelText: 'Torre / Block')
                  ),
                
                TextField(
                  controller: _numeroCtrl, 
                  decoration: InputDecoration(
                    labelText: isEdificio ? 'Nº Depto' : 'Nº Casa / Parcela'
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () => _createPendingResident(ctx, isEdificio: isEdificio), 
              child: const Text('Invitar')
            ),
          ],
        );
      }
    );
  }

  Future<void> _createPendingResident(BuildContext dialogContext, {required bool isEdificio}) async {
    final email = _emailCtrl.text.trim();
    final nombre = _nombreCtrl.text.trim();
    final apellido = _apellidoCtrl.text.trim();
    final numero = _numeroCtrl.text.trim();
    final torre = _torreCtrl.text.trim();
    
    // CAMBIO CLAVE: Tomamos el condominioId
    final condominioId = widget.appState.adminState.currentCondominioId;

    if (email.isEmpty || nombre.isEmpty || apellido.isEmpty || numero.isEmpty || (isEdificio && torre.isEmpty)) {
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
          .collection('Residentes')
          .where('correo', isEqualTo: email)
          .limit(1) 
          .get();

      if (duplicateCheck.docs.isNotEmpty) {
          if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Este correo ya tiene una invitación o está registrado.'),
                    backgroundColor: Colors.orange,
                  )
              );
          }
          return; 
      }
      
      // CAMBIO CLAVE: Guardamos solo la estructura limpia
      final Map<String, dynamic> residentData = {
        'condominioId': condominioId, // Nueva relación
        'correo': email,
        'nombre': nombre,
        'apellido': apellido,
        'estado': 'Pendiente',
        'rol': 'Residente',
        'createdAt': FieldValue.serverTimestamp(),
        'numero': numero,
        'torre': isEdificio ? torre : null,
        'uid': null, 
      };

      await FirebaseFirestore.instance.collection('Residentes').add(residentData);
      
      if (dialogContext.mounted) {
        Navigator.of(dialogContext).pop(); 
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Residente invitado con éxito.'))
        );
      }

    } catch (e) {
      print("Error al invitar: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // CAMBIO CLAVE: Filtramos por condominioId
    final condominioId = widget.appState.adminState.currentCondominioId;

    if (condominioId == null) {
      return const Center(child: Text('Cargando condominio...'));
    }

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Residentes')
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
            return const Center(child: Text('Aún no has invitado residentes.'));
          }

          final residents = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: residents.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final data = residents[i].data() as Map<String, dynamic>;
              
              final String subtitle = 
                  data['torre'] != null && data['torre'].toString().isNotEmpty
                  ? 'Torre ${data['torre']} - ${data['numero']}' 
                  : 'Nº ${data['numero']}';
              
              final String estado = data['estado'] ?? 'Pendiente';
              
              final String title = '${data['nombre']} ${data['apellido']}';

              return Card(
                child: ListTile(
                  title: Text(title),
                  subtitle: Text(subtitle),
                  trailing: Chip(
                    label: Text(estado, style: const TextStyle(fontSize: 12)),
                    backgroundColor: estado == 'Registrado' 
                        ? Colors.green.shade50 
                        : Colors.grey.shade200,
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