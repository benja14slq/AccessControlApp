import 'package:accesscontrol/guard/state/guard_state.dart';
import 'package:accesscontrol/shared/utils.dart';
import 'package:flutter/material.dart';

class GuardEventsPage extends StatelessWidget {
  const GuardEventsPage({super.key, required this.state});
  final GuardState state;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: state.events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final event = state.events[i];
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