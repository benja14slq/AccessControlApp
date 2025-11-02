// lib/admin/screens/admin_logbook_page.dart

import 'package:accesscontrol/shared/utils.dart';
import 'package:accesscontrol/state/app_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminLogbookPage extends StatelessWidget {
  // 1. Cambiamos el constructor
  const AdminLogbookPage({super.key, required this.appState});
  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final adminUid = appState.adminState.adminUid;

    if (adminUid == null) {
      return const Center(child: Text('Cargando datos de administrador...'));
    }

    // 2. Usamos un StreamBuilder para leer la bitácora
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Visitas')
          .where('adminUid', isEqualTo: adminUid) // Filtra por el admin
          .orderBy('createdAt', descending: true) // Muestra las más nuevas primero
          .limit(50) // Limita a los últimos 50 eventos
          .snapshots(),
      
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Sin eventos de visitas registrados.'));
        }

        final events = snapshot.data!.docs;

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: events.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final data = events[i].data() as Map<String, dynamic>;
            final status = data['status'] ?? 'programada';
            
            // Lógica simple para íconos y descripción
            IconData icon = Icons.event_note;
            Color color = Colors.blueGrey;
            if (status == 'autorizada') {
              icon = Icons.check_circle_outline;
              color = Colors.green;
            } else if (status == 'rechazada') {
              icon = Icons.cancel_outlined;
              color = Colors.red;
            }

            return Card(
              child: ListTile(
                leading: Icon(icon, color: color),
                title: Text('Visita: ${data['visitorName']}'),
                subtitle: Text(
                  'Estado: $status • ${formatCompact((data['createdAt'] as Timestamp).toDate())}'
                ),
              ),
            );
          },
        );
      },
    );
  }
}