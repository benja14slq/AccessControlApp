import 'package:accesscontrol/guard/state/guard_state.dart';
import 'package:accesscontrol/shared/utils.dart';
import 'package:flutter/material.dart';

class GuardEventsPage extends StatelessWidget {
  const GuardEventsPage({super.key, required this.state});
  final GuardState state;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state, 
      builder: (context, child) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.events.isEmpty){
          return const Center(
            child: Text(
              'No hay eventos registrados.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: state.events.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final event = state.events[i];

            IconData icon = Icons.info_outline;
            Color color = Colors.blueGrey;
            if (event.description.contains('autorizado')){
              icon = Icons.check_circle_outline;
              color = Colors.green;
            } else if (event.description.contains('rechazado')){
              icon = Icons.cancel_outlined;
              color = Colors.red;
            } else if (event.description.contains('manual')){
              icon = Icons.key_outlined;
              color = Colors.orange;
            }

            return Card(
              child: ListTile(
                leading: Icon(icon, color: color),
                title: Text(event.description),
                subtitle: Text(formatCompact(event.timestamp)),
              ),
            );
          },
        );
      }
    );
  }
}