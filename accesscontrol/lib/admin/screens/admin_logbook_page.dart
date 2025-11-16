import 'package:accesscontrol/shared/format.dart';
import 'package:accesscontrol/state/app_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminLogbookPage extends StatefulWidget {
  const AdminLogbookPage({super.key, required this.appState});
  final AppState appState;

  @override
  State<AdminLogbookPage> createState() => _AdminLogbookPageState();
}

class _AdminLogbookPageState extends State<AdminLogbookPage> {

  String? _selectedResidentUid;
  String? _selectedTower;

  List<QueryDocumentSnapshot> _residents = [];
  List<String> _towers = [];
  bool _isLoadingResidents = true;

  @override
  void initState(){
    super.initState();
    _loadResidentFilters();
  }

  Future<void> _loadResidentFilters() async {
    final adminUid = widget.appState.adminState.adminUid;
    if (adminUid == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Residentes')
          .where('adminUid', isEqualTo: adminUid)
          .where('estado', isEqualTo: 'Registrado')
          .get();

      final uniqueTowers = <String>{};
      for (final doc in snapshot.docs){
        final data = doc.data();
        if (data['torre'] != null && (data['torre'] as String).isNotEmpty){
          uniqueTowers.add(data['torre']);
        }
      }
      setState(() {
        _residents = snapshot.docs;
        _towers = uniqueTowers.toList()..sort();
        _isLoadingResidents = false;
      });
    } catch (e) {
      print("Error cargando filtros: $e");
      setState(() => _isLoadingResidents = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminUid = widget.appState.adminState.adminUid;
    final bool isEdificio = widget.appState.adminState.adminCondoTypeId
        ?.toLowerCase().contains('edificios') ?? false;

    Query query = FirebaseFirestore.instance
        .collection('Eventos')
        .where('adminUid', isEqualTo: adminUid)
        .orderBy('timestamp', descending: true)
        .limit(50);

    if (_selectedResidentUid != null) {
      query = query.where('residentUid', isEqualTo: _selectedResidentUid);
    }
    if (_selectedTower != null) {
      query = query.where('residentTower', isEqualTo: _selectedTower);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
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
                    return DropdownMenuItem<String>(
                      value: data['uid'],
                      child: Text('${data['nombre']} ${data['apellido']}'),
                    );
                  }).toList(),
                  selectedItemBuilder: (context) => _residents.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return Text('${data['nombre']} ${data['apellido']}', overflow: TextOverflow.ellipsis);
                  }).toList(),
                ),
              ),
              if (_selectedResidentUid != null)
                IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _selectedResidentUid = null)),
              
              if (isEdificio) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedTower,
                    hint: const Text('Filtrar por Torre'),
                    onChanged: (value) => setState(() => _selectedTower = value),
                    items: _towers.map((torre) {
                      return DropdownMenuItem(value: torre, child: Text(torre));
                    }).toList(),
                  ),
                ),
                if (_selectedTower != null)
                  IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _selectedTower = null)),
              ]
            ],
          ),
        ),
        const Divider(height: 1),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: query.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('Sin eventos registrados (o que coincidan con el filtro).'));
              }

              final events = snapshot.data!.docs;

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: events.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final data = events[i].data() as Map<String, dynamic>;
                  final status = data['status'] ?? 'desconocido';
                  
                  IconData icon = Icons.info_outline;
                  Color color = Colors.blueGrey;
                  if (status.contains('autorizada')) {
                    icon = Icons.check_circle_outline;
                    color = Colors.green;
                  } else if (status.contains('rechazada')) {
                    icon = Icons.cancel_outlined;
                    color = Colors.red;
                  } else if (status.contains('manual')) {
                    icon = Icons.key_outlined;
                    color = Colors.orange;
                  }

                  final String residentInfo = data['residentName'] != null
                      ? '\nResidente: ${data['residentName']}'
                      : '';

                  return Card(
                    child: ListTile(
                      leading: Icon(icon, color: color),
                      title: Text(data['description'] ?? 'Evento sin descripción'),
                      subtitle: Text(
                        'Estado: $status • ${formatCompact((data['timestamp'] as Timestamp).toDate())}$residentInfo'
                      ),
                      isThreeLine: residentInfo.isNotEmpty,
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