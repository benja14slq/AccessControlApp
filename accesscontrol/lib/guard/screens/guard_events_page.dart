import 'package:accesscontrol/guard/state/guard_state.dart';
import 'package:accesscontrol/shared/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GuardEventsPage extends StatefulWidget {
  const GuardEventsPage({super.key, required this.state});
  final GuardState state;

  @override
  State<GuardEventsPage> createState() => _GuardEventsPageState();
}

class _GuardEventsPageState extends State<GuardEventsPage> {
  String? _selectedResidentUid;
  List<QueryDocumentSnapshot> _residents = [];
  bool _isLoadingResidents = true;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadResidentFilters();
  }

  Future<void> _loadResidentFilters() async {
    // CAMBIO: Ahora obtenemos el condominioId desde el estado
    final condominioId = widget.state.condominioId;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Residentes')
          .where('condominioId', isEqualTo: condominioId) // CAMBIO
          .where('estado', isEqualTo: 'Registrado')
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
    final startOfDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      0,
      0,
      0,
    );
    final endOfDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      23,
      59,
      59,
    );

    Query query = FirebaseFirestore.instance
        .collection('Eventos')
        .where('condominioId', isEqualTo: widget.state.condominioId)
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('timestamp', descending: true)
        .limit(100);

    if (_selectedResidentUid != null) {
      query = query.where('residentUid', isEqualTo: _selectedResidentUid);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Eventos del: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.indigo,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.calendar_month, color: Colors.indigo),
                onPressed: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2023),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null && picked != _selectedDate) {
                    setState(() {
                      _selectedDate = picked;
                    });
                  }
                },
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedResidentUid,
                  hint: Text(
                    _isLoadingResidents
                        ? 'Cargando...'
                        : 'Filtrar por Residente',
                  ),
                  onChanged: (value) =>
                      setState(() => _selectedResidentUid = value),
                  items: _residents.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    String torre = data['torre'] ?? '';
                    String numero = data['numero'] ?? '';
                    String unit =
                        (torre.isNotEmpty ? 'Torre $torre - ' : 'Nº ') + numero;
                    String name = '${data['nombre']} ${data['apellido']}';

                    return DropdownMenuItem<String>(
                      value: data['uid'],
                      child: Text(
                        '$name ($unit)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  selectedItemBuilder: (context) => _residents.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    String torre = data['torre'] ?? '';
                    String numero = data['numero'] ?? '';
                    String unit =
                        (torre.isNotEmpty ? 'Torre $torre - ' : 'Nº ') + numero;
                    String name = '${data['nombre']} ${data['apellido']}';

                    return Text(
                      '$name ($unit)',
                      overflow: TextOverflow.ellipsis,
                    );
                  }).toList(),
                ),
              ),
              if (_selectedResidentUid != null)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() => _selectedResidentUid = null),
                ),
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
                return const Center(
                  child: Text(
                    'No hay eventos en este día.',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              final events = snapshot.data!.docs;

              return ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: events.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final data = events[i].data() as Map<String, dynamic>;
                  final rawStatus = data['status'] ?? 'desconocido';

                  IconData icon = Icons.info_outline;
                  Color color = Colors.blueGrey;
                  if (rawStatus.contains('autorizada')) {
                    icon = Icons.check_circle_outline;
                    color = Colors.green;
                  } else if (rawStatus.contains('rechazada')) {
                    icon = Icons.cancel_outlined;
                    color = Colors.red;
                  } else if (rawStatus.contains('manual')) {
                    icon = Icons.key_outlined;
                    color = Colors.orange;
                  } else if (rawStatus.contains('notificacion')) {
                    icon = Icons.notifications_active;
                    color = Colors.blue;
                  }

                  String statusText = 'Desconocido';
                  switch (rawStatus) {
                    case 'autorizada_qr':
                      statusText = 'Autorizado (Pase QR)';
                      break;
                    case 'rechazada_qr':
                      statusText = 'Rechazado (Pase QR)';
                      break;
                    case 'autorizada_facial':
                      statusText = 'Autorizado (Biometría)';
                      break;
                    case 'rechazada_facial':
                      statusText = 'Rechazado (Biometría)';
                      break;
                    case 'autorizada_lpr':
                      statusText = 'Autorizado (Patente)';
                      break;
                    case 'rechazada_lpr':
                      statusText = 'Rechazado (Patente)';
                      break;
                    case 'autorizada_manual':
                      statusText = 'Ingreso Manual Registrado';
                      break;
                    case 'autorizada_notificacion':
                      statusText = 'Autorizado por Residente';
                      break;
                  }

                  final String residentInfo = data['residentName'] != null
                      ? 'Residente: ${data['residentName']}'
                      : '';

                  return Card(
                    elevation: 1,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withOpacity(0.1),
                          child: Icon(icon, color: color),
                        ),
                        title: Text(
                          data['description'] ?? 'Evento sin descripción',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.symmetric(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                // Se cambia "Hace X tiempo" por la hora exacta (ej. 14:30)
                                '$statusText • ${DateFormat('HH:mm').format((data['timestamp'] as Timestamp).toDate())} hrs',
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              if (residentInfo.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  residentInfo,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        isThreeLine: residentInfo.isNotEmpty,
                      ),
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
