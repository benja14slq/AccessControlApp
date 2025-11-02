import 'package:accesscontrol/resident/state/resident_state.dart';
import 'package:accesscontrol/shared/widgets/status_chip.dart';
import 'package:accesscontrol/shared/utils.dart';
import 'package:flutter/material.dart';

class MyVisitsPage extends StatelessWidget {
  const MyVisitsPage({super.key, required this.state});
  final ResidentState state;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state, 
      builder: (context, child) {
        
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final proximasVisitas = state.upcomingVisits;

        if (proximasVisitas.isEmpty) {
          return const Center(
            child: Text(
              'No tienes pases programados. \nCrea uno en la pestaña "Generar".',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          separatorBuilder: (_, __) => const SizedBox(height: 8), 
          itemCount: proximasVisitas.length,
          itemBuilder: (context, i) {
            final v = proximasVisitas[i];
            return Card(
              child: ListTile(
                title: Text(v.visitorName),
                subtitle: Text('${formatCompact(v.scheduledAt)} • Código: ${v.code}'),
                trailing: StatusChip(v.status),
              ),
            );
          }
        );
      }
    );
  }
}