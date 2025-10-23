import 'package:accesscontrol/resident/state/resident_state.dart';
import 'package:accesscontrol/shared/widgets/status_chip.dart';
import 'package:accesscontrol/shared/utils.dart';
import 'package:flutter/material.dart';

class MyVisitsPage extends StatelessWidget {
  const MyVisitsPage({super.key, required this.state});
  final ResidentState state;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      separatorBuilder: (_, __) => const SizedBox(height: 8), 
      itemCount: state.visits.length,
      itemBuilder: (context, i) {
        final v = state.visits[i];
        return Card(
          child: ListTile(
            title: Text(v.visitorName),
            subtitle: Text('${formatCompact(v.scheduledAt)} • Código: ${v.code}'),
            trailing: StatusChip(v.status),
          ),
        );
      }, 
    );
  }
}