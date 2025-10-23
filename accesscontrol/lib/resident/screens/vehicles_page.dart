import 'package:accesscontrol/resident/state/resident_state.dart';
import 'package:flutter/material.dart';

class VehiclesPage extends StatefulWidget {
  const VehiclesPage({super.key, required this.state});
  final ResidentState state;

  @override
  State<VehiclesPage> createState() => _VehiclesPageState();
}

class _VehiclesPageState extends State<VehiclesPage> {
  final _plateCtrl = TextEditingController();
  final _aliasCtrl = TextEditingController();

  @override
  void dispose() {
    _plateCtrl.dispose();
    _aliasCtrl.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Mis vehículos', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Expanded(
          child: widget.state.vehicles.isEmpty
            ? const Center(child: Text('Sin vehículos registrados.', style: TextStyle(color: Colors.grey)))
            : ListView.separated(
              itemCount: widget.state.vehicles.length, 
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final v = widget.state.vehicles[i];
                return Dismissible(
                  key: ValueKey('${v.plate}-$i'),
                  background: Container(color: Colors.redAccent),
                  onDismissed: (_) => setState(() => widget.state.removeVehicleAt(i)), 
                  child: Card(
                    child: ListTile(
                      title: Text(v.plate),
                      subtitle: Text(v.alias ?? 'Sin alias'),
                      trailing: IconButton(
                        onPressed: () => setState(() => widget.state.removeVehicleAt(i)), 
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ),
                  ),
                );
              },
            ),
        ),
        const SizedBox(height: 8),
        TextField(controller: _plateCtrl, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Patente')),
        const SizedBox(height: 8),
        TextField(controller: _aliasCtrl, decoration: const InputDecoration(labelText: 'Alias (opcional)')),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: () {
            final p = _plateCtrl.text.trim().toUpperCase();
            final a = _aliasCtrl.text.trim();
            if (p.isEmpty){
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa la patente')));
              return;
            }
            setState(() {
              widget.state.addVehicle(p, a.isEmpty ? null : a);
              _plateCtrl.clear();
              _aliasCtrl.clear();
            });
          }, 
          icon: const Icon(Icons.add),
          label: const Text('Agregar vehículo'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        ),
      ]),
    );
  }
}