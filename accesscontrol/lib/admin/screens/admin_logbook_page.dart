import 'package:accesscontrol/guard/state/guard_state.dart';
import 'package:accesscontrol/shared/utils.dart';
import 'package:flutter/material.dart';

// La bitácora del admin es la misma que la del guardia
// (en un futuro, podría tener más filtros o data)
class AdminLogbookPage extends StatelessWidget {
  const AdminLogbookPage({super.key, required this.guardState});
  final GuardState guardState;

  @override
  Widget build(BuildContext context) {
    
    if (guardState.events.isEmpty) {
      return const Center(child: Text('Sin eventos registrados hoy.', style: TextStyle(color: Colors.grey)));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: guardState.events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final event = guardState.events[i];
        return Card(
          child: ListTile(
            leading: Icon(
              event.description.contains('AUTORIZADO') ? Icons.check_circle_outline : 
              event.description.contains('rechazado') ? Icons.cancel_outlined : 
              Icons.key_outlined,
              color: event.description.contains('AUTORIZADO') ? Colors.green : 
              event.description.contains('rechazado') ? Colors.red : 
              Colors.blueGrey,
            ),
            title: Text(event.description),
            subtitle: Text(formatCompact(event.timestamp)),
          ),
        );
      },
    );
  }
}