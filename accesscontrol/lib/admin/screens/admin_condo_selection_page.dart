import 'package:accesscontrol/shared/models.dart';
import 'package:accesscontrol/state/app_state.dart';
import 'package:flutter/material.dart';

class AdminCondoSelectionPage extends StatefulWidget {
  const AdminCondoSelectionPage({super.key, required this.appState});
  final AppState appState;

  @override
  State<AdminCondoSelectionPage> createState() => _AdminCondoSelectionPageState();
}

class _AdminCondoSelectionPageState extends State<AdminCondoSelectionPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  String? _selectedTypeId;
  bool _isLoading = false;

  @override
  void dispose(){
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _showCreateDialog() async {
    _nameCtrl.clear();
    _selectedTypeId = null;

    // SOLUCIÓN: Capturamos el mensajero usando el context de la PÁGINA, fuera del diálogo
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context, 
      // Cambiamos el nombre de la variable aquí a 'dialogCtx' para no sobreescribir 'context'
      builder: (dialogCtx) => StatefulBuilder(
        builder: (innerCtx, setStateDialog) {
          return AlertDialog(
            title: const Text('Registrar Nuevo Condominio'),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Este nuevo condominio se vinculará con tu cuenta de Administrador.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre del Condominio/Edificio'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedTypeId,
                    decoration: const InputDecoration(labelText: 'Tipo de Entorno'),
                    validator: (value) => value == null ? 'Selecciona un tipo' : null,
                    items: widget.appState.condoTypes.map((type) {
                      return DropdownMenuItem(
                        value: type.id,
                        child: Text(type.name),
                      );
                    }).toList(), 
                    onChanged: (value) {
                      setStateDialog(() => _selectedTypeId = value);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: _isLoading ? null : () => Navigator.pop(dialogCtx), 
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: _isLoading ? null : () async {
                  if (!_formKey.currentState!.validate()) return;

                  setStateDialog(() => _isLoading = true);
                  bool success = false;

                  try {
                    await widget.appState.adminState.createAndLinkNewCondominio(
                      _nameCtrl.text.trim(), 
                      _selectedTypeId!,
                    );
                    success = true; 
                  } catch (e) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)
                    );
                  } finally {
                    if (success) {
                      Navigator.pop(dialogCtx); // Cerramos el diálogo usando su propio contexto
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(content: Text('¡Condominio creado y vinculado con éxito!'))
                      );
                    } else {
                      if (mounted) {
                        setStateDialog(() => _isLoading = false);
                      }
                    }
                  }
                }, 
                child: _isLoading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Crear Recinto'),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.appState.adminState;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Condominio'),
        centerTitle: true,
      ),
      body: state.availableCondos.isEmpty
          ? const Center(child: Text('No tienes condominios asignados.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.availableCondos.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final condo = state.availableCondos[index];
                return _CondoCard(
                  condo: condo,
                  onTap: () => state.selectCondominio(condo),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.add_business),
        label: const Text('Nuevo Condominio'),
      ),
    );
  }
}

class _CondoCard extends StatelessWidget {
  const _CondoCard({required this.condo, required this.onTap});
  final Condominio condo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                child: Icon(Icons.business, color: Theme.of(context).primaryColor),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      condo.nombreCondominio,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      maxLines: 2, 
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Toca para gestionar este condominio',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}