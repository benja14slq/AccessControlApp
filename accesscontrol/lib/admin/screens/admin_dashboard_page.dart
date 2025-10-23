import 'package:accesscontrol/shared/models.dart';
import 'package:accesscontrol/shared/widgets/stat_card.dart';
import 'package:accesscontrol/state/app_state.dart';
import 'package:flutter/material.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key, required this.appState});
  final AppState appState;

  @override
  Widget build(BuildContext context) {
    // Obtenemos data de los otros estados para el dashboard
    final residentCount = appState.adminState.users.where((u) => u.role == 'Residente').length;
    final guardCount = appState.adminState.users.where((u) => u.role == 'Guardia').length;
    final vehiclesCount = appState.residentState.vehicles.length;
    final visitsToday = appState.residentState.visits.where((v) => v.status == VisitStatus.programada).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Estado del Condominio', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: StatCard(label: 'Residentes', value: residentCount.toString())),
              const SizedBox(width: 8),
              Expanded(child: StatCard(label: 'Guardias', value: guardCount.toString())),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: StatCard(label: 'Vehículos Reg.', value: vehiclesCount.toString())),
              const SizedBox(width: 8),
              Expanded(child: StatCard(label: 'Visitas Prog.', value: visitsToday.toString())),
            ],
          ),
          // Aquí se podrían agregar gráficos, etc.
        ],
      ),
    );
  }
}