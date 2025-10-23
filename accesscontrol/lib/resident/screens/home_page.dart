import 'package:accesscontrol/resident/state/resident_state.dart';
import 'package:accesscontrol/shared/widgets/stat_card.dart';
import 'package:accesscontrol/shared/widgets/status_chip.dart';
import 'package:accesscontrol/shared/utils.dart';
import 'package:flutter/material.dart';
import 'package:accesscontrol/shared/models.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.state, required this.goToCreate, required this.goToVisits});
  final ResidentState state;
  final VoidCallback goToCreate;
  final VoidCallback goToVisits;

  @override
  Widget build(BuildContext context) {
    final proximas = state.visits.where((v) => v.status == VisitStatus.programada).take(3).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if(!state.hasFaceId)
            Card(
              color: Colors.amber.shade50,
              child: ListTile(
                title: const Text('Completa tu perfil de acceso'),
                subtitle: const Text('Aún no registrar biometria facial.'),
                trailing: TextButton(onPressed: state.toggleFaceId, child: const Text('Registrar ahora')),
              ),
            ),
          const SizedBox(height: 12),
          Text('Estado General', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: StatCard(label: 'Mis vehículos', value: state.vehicles.length.toString())),
              const SizedBox(width: 8),
              Expanded(child: StatCard(label: 'Visitas hoy', value: proximas.length.toString())),
              const SizedBox(width: 8),
              Expanded(child: StatCard(label: 'Pases activos', value: state.visits.where((v) => v.status != VisitStatus.expirada).length.toString())),
            ],
          ),
          const SizedBox(height: 16),
          Text('Acciones rápidas', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: goToCreate, 
                icon: const Icon(Icons.qr_code_2),
                label: const Text('Generar pase'),
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: goToVisits, 
                icon: const Icon(Icons.list_alt),
                label: const Text('Mis visitas'),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          Text('Proximas llegadas', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (proximas.isEmpty) const Text('Sin visitas programadas.', style: TextStyle(color: Colors.grey)),
          ...proximas.map((v) => Card(
            child: ListTile(
              title: Text(v.visitorName),
              subtitle: Text('${formatCompact(v.scheduledAt)} • Código: ${v.code}'),
              trailing: StatusChip(v.status),
            ),
          )),
        ],
      ),
    );
  }
}