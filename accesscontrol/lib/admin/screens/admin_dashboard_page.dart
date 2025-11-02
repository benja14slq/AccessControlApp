// lib/admin/screens/admin_dashboard_page.dart

import 'package:accesscontrol/shared/widgets/stat_card.dart';
import 'package:accesscontrol/state/app_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key, required this.appState});
  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final adminUid = appState.adminState.adminUid;
    final db = FirebaseFirestore.instance;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Estado del Condominio', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          
          // Fila 1: Conteo de Residentes y Guardias
          Row(
            children: [
              // Usamos un 'StreamWidget' para el conteo de residentes
              _buildCountCard(
                collection: db.collection('Residentes'),
                adminUid: adminUid,
                label: 'Residentes',
              ),
              const SizedBox(width: 8),
              // Usamos un 'StreamWidget' para el conteo de guardias
              _buildCountCard(
                collection: db.collection('Guardias'),
                adminUid: adminUid,
                label: 'Guardias',
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Fila 2: Conteo de Vehículos y Visitas
          Row(
            children: [
              // Usamos un 'StreamWidget' para el conteo de vehículos
              _buildCountCard(
                collection: db.collectionGroup('Vehiculos'), // Busca en subcolecciones
                adminUid: adminUid,
                label: 'Vehículos Reg.',
              ),
              const SizedBox(width: 8),
              // Usamos un 'StreamWidget' para el conteo de visitas
              _buildCountCard(
                collection: db.collection('Visitas'),
                adminUid: adminUid,
                label: 'Visitas Prog.',
                fieldFilters: [ // Filtro extra
                  Filter('status', isEqualTo: 'programada')
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget reutilizable para construir una StatCard con datos de Firestore
  Widget _buildCountCard({
    required Query collection,
    required String? adminUid,
    required String label,
    List<Filter>? fieldFilters,
  }) {
    // Aplica el filtro base de adminUid
    Query query = collection.where('adminUid', isEqualTo: adminUid);

    // Aplica filtros adicionales si existen
    if (fieldFilters != null) {
      for (final filter in fieldFilters) {
        query = query.where(filter);
      }
    }

    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const StatCard(label: '...', value: '...');
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return StatCard(label: label, value: '0');
          }
          // Obtenemos el número de documentos
          final count = snapshot.data!.docs.length.toString();
          return StatCard(label: label, value: count);
        },
      ),
    );
  }
}