import 'package:accesscontrol/guard/state/guard_state.dart';
import 'package:accesscontrol/shared/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <-- AÑADIR
import 'package:flutter/material.dart';

// --- CONVERTIR A STATEFULWIDGET ---
class GuardEventsPage extends StatefulWidget {
  const GuardEventsPage({super.key, required this.state});
  final GuardState state;

  @override
  State<GuardEventsPage> createState() => _GuardEventsPageState();
}

class _GuardEventsPageState extends State<GuardEventsPage> {
  // --- ESTADO PARA FILTROS ---
  String? _selectedResidentUid;
  List<QueryDocumentSnapshot> _residents = [];
  bool _isLoadingResidents = true;

  @override
  void initState() {
    super.initState();
    _loadResidentFilters();
  }

  // --- FUNCIÓN PARA CARGAR FILTROS ---
  Future<void> _loadResidentFilters() async {
    // Usamos el getter público que creamos en GuardState
    final adminUid = widget.state.adminUid; 

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Residentes')
          .where('adminUid', isEqualTo: adminUid)
          .where('estado', isEqualTo: 'Registrado') // Solo residentes activos
          .orderBy('nombre')
          .get();
      
      setState(() {
        _residents = snapshot.docs;
        _isLoadingResidents = false;
      });

    } catch (e) {
      print("Error cargando residentes: $e");
      setState(() => _isLoadingResidents = false);
    }
  }

  @override
  Widget build(BuildContext context) {

    // --- CONSTRUCCIÓN DE CONSULTA DINÁMICA ---
    Query query = FirebaseFirestore.instance
        .collection('Eventos')
        .where('adminUid', isEqualTo: widget.state.adminUid) // Filtra por el admin del guardia
        .orderBy('timestamp', descending: true)
        .limit(50);

    if (_selectedResidentUid != null) {
      // Aplica el filtro de residente si está seleccionado
      query = query.where('residentUid', isEqualTo: _selectedResidentUid);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedResidentUid,
                  hint: Text(_isLoadingResidents ? 'Cargando...' : 'Filtrar por Residente'),
                  onChanged: (value) => setState(() => _selectedResidentUid = value),
                  items: _residents.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    // Construir nombre y unidad
                    String torre = data['torre'] ?? '';
                    String numero = data['numero'] ?? '';
                    String unit = (torre.isNotEmpty ? 'Torre $torre - ' : 'Nº ') + numero;
                    String name = '${data['nombre']} ${data['apellido']}';
                    
                    return DropdownMenuItem<String>(
                      value: data['uid'], // <-- Usar Auth UID para el filtro
                      child: Text('$name ($unit)', overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  // Muestra el item seleccionado con el texto completo
                  selectedItemBuilder: (context) => _residents
                    .where((doc) => doc['uid'] == _selectedResidentUid)
                    .map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      String torre = data['torre'] ?? '';
                      String numero = data['numero'] ?? '';
                      String unit = (torre.isNotEmpty ? 'Torre $torre - ' : 'Nº ') + numero;
                      String name = '${data['nombre']} ${data['apellido']}';
                      return Text('$name ($unit)', overflow: TextOverflow.ellipsis);
                    }).toList(),
                ),
              ),
              if (_selectedResidentUid != null)
                IconButton(
                  icon: const Icon(Icons.clear), 
                  onPressed: () => setState(() => _selectedResidentUid = null)
                ),
            ],
          ),
        ),
        const Divider(height: 1),

        // --- STREAMBUILDER BASADO EN LA CONSULTA ---
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: query.snapshots(),
            builder: (context, snapshot) {
              // Ya no usamos AnimatedBuilder ni state.events
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    'No hay eventos registrados.',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              final events = snapshot.data!.docs;

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: events.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final data = events[i].data() as Map<String, dynamic>;
                  final status = data['status'] ?? 'desconocido';

                  IconData icon = Icons.info_outline;
                  Color color = Colors.blueGrey;
                  if (status.contains('autorizada')){
                    icon = Icons.check_circle_outline;
                    color = Colors.green;
                  } else if (status.contains('rechazada')){
                    icon = Icons.cancel_outlined;
                    color = Colors.red;
                  } else if (status.contains('manual')){
                    icon = Icons.key_outlined;
                    color = Colors.orange;
                  }

                  return Card(
                    child: ListTile(
                      leading: Icon(icon, color: color),
                      title: Text(data['description']),
                      subtitle: Text(formatCompact((data['timestamp'] as Timestamp).toDate())),
                      isThreeLine: data['description'].contains('\n'),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}