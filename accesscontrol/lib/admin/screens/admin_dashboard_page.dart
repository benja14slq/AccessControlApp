import 'package:accesscontrol/shared/widgets/stat_card.dart';
import 'package:accesscontrol/state/app_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key, required this.appState});
  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final condominioId = appState.adminState.currentCondominioId;
    final db = FirebaseFirestore.instance;

    if (condominioId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Estado del Condominio', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          
          Row(
            children: [
              _buildCountCard(
                collection: db.collection('Residentes'),
                condominioId: condominioId,
                label: 'Residentes',
              ),
              const SizedBox(width: 8),
              _buildCountCard(
                collection: db.collection('Guardias'),
                condominioId: condominioId,
                label: 'Guardias',
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              _buildCountCard(
                collection: db.collectionGroup('Vehiculos'), 
                condominioId: condominioId,
                label: 'Vehículos Reg.',
              ),
              const SizedBox(width: 8),
              _buildCountCard(
                collection: db.collection('Visitas'),
                condominioId: condominioId,
                label: 'Visitas Prog.',
                fieldFilters: [ 
                  Filter('status', isEqualTo: 'programada')
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCountCard({
    required Query collection,
    required String? condominioId,
    required String label,
    List<Filter>? fieldFilters,
  }) {

    Query query = collection.where('condominioId', isEqualTo: condominioId);

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
          final count = snapshot.data!.docs.length.toString();
          return StatCard(label: label, value: count);
        },
      ),
    );
  }
}