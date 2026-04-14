import 'package:accesscontrol/resident/state/resident_state.dart';
import 'package:accesscontrol/shared/utils.dart';
import 'package:accesscontrol/shared/widgets/stat_card.dart';
import 'package:accesscontrol/shared/widgets/status_chip.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.state, required this.goToCreate, required this.goToVisits, required this.goToSettings});
  final ResidentState state;
  final VoidCallback goToCreate;
  final VoidCallback goToVisits;
  final VoidCallback goToSettings;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state, 
      builder: (context, child) {
        if (state.isLoading){
          return const Center(child: CircularProgressIndicator());
        }

        final proximas = state.upcomingVisits.take(3).toList();
        final visitasHoyCount = state.visitsTodayCount.toString();
        final pasesActivosCount = state.upcomingVisits.length.toString();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola, ${state.residentName}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_city, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${state.condoName} - ${state.condoUnit}',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if(!state.hasFaceId)
                Card(
                  color: Colors.amber.shade50,
                  child: ListTile(
                    title: const Text('Completa tu perfil de acceso'),
                    subtitle: const Text('Aún no registras biometría facial.'),
                    trailing: TextButton(onPressed: goToSettings, child: const Text('Register ahora')),
                  ),
                ),

                if(!state.hasFaceId)
                  const SizedBox(height: 12),
                
                Text('Estado general', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: StatCard(label: 'Mis Vehículos', value: state.vehicles.length.toString())),
                    const SizedBox(width: 8),
                    Expanded(child: StatCard(label: 'Visitas hoy', value: visitasHoyCount)),
                    const SizedBox(width: 8),
                    Expanded(child: StatCard(label: 'Pases activos', value: pasesActivosCount)),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Acciones Rápidas', style: Theme.of(context).textTheme.titleMedium),

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
                      label: const Text('Mis Visitas'),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                Text('Proximas llegadas', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),

                if(proximas.isEmpty) const Text('Sin visitas programadas', style: TextStyle(color: Colors.grey)),

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
    );
  }
}