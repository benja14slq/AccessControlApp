import 'package:accesscontrol/resident/state/resident_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ResidentState>();
    final notifications = state.pendingNotifications;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitas Pendientes'),
      ),
      body: notifications.isEmpty
          ? const Center(
            child: Text('No tienes visitas pendientes de aprobación'),
          )
          : ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final doc = notifications[index];
              final data = doc.data() as Map<String, dynamic>;
              final visitorName = data['visitorName'] ?? 'Visitante';
              final guardName = data['guardName'] ?? 'Guardia';

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visitorName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text('Anunciado por: $guardName'),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              state.respondToNotification(doc.id, false);
                            },
                            style: TextButton.styleFrom(foregroundColor: Colors.red), 
                            child: const Text('Rechazar'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () {
                              state.respondToNotification(doc.id, false);
                            }, 
                            child: const Text('Aprobar'),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            }
          )
    );
  }
}