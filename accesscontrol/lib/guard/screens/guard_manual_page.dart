import 'dart:async';
import 'package:accesscontrol/guard/state/guard_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class GuardManualPage extends StatefulWidget {
  const GuardManualPage({super.key, required this.state});
  final GuardState state;

  @override
  State<GuardManualPage> createState() => _GuardManualPageState();
}

class _GuardManualPageState extends State<GuardManualPage> {
  String? _selectedTower;
  String? _selectedResidentUid; 
  final _visitorNameCtrl = TextEditingController();

  bool _isLoading = false;
  String _result = '';
  bool _isSuccess = false;
  bool _isNotifying = false;
  StreamSubscription? _notificationSub;

  @override
  void dispose() {
    _visitorNameCtrl.dispose();
    _notificationSub?.cancel();
    super.dispose();
  }

  List<Map<String, dynamic>> _getFilteredResidents() {
    if (widget.state.towers.isEmpty) {
      return widget.state.residentsList; 
    }
    if (_selectedTower == null) {
      return []; 
    }
    return widget.state.residentsList.where((r) => r['torre'] == _selectedTower).toList();
  }

  Future<void> _processAction({required bool isNotification}) async {
    if (_selectedResidentUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona un residente')));
      return;
    }
    if (isNotification && _visitorNameCtrl.text.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa nombre del visitante')));
       return;
    }

    setState(() {
      _isLoading = !isNotification;
      _isNotifying = isNotification;
      _result = '';
    });

    final residentData = widget.state.residentsList.firstWhere((r) => r['uid'] == _selectedResidentUid);

    final result = await widget.state.notifyOrLogManual(
      residentUid: residentData['uid'],
      residentName: residentData['nombre'],
      torre: residentData['torre'],
      numero: residentData['numero'],
      visitorName: isNotification ? _visitorNameCtrl.text.trim() : null,
    );

    if (result['status'] == 'notificando') {
      _updateUI(result);
      _notificationSub?.cancel();
      _notificationSub = FirebaseFirestore.instance
          .collection('notificaciones_visita')
          .doc(result['docId'])
          .snapshots()
          .listen(_onNotificationUpdate);
    } else {
      _updateUI(result);
      setState(() => _isNotifying = false);
    }
  }

  void _onNotificationUpdate(DocumentSnapshot snapshot) {
    if (!snapshot.exists) return;
    final data = snapshot.data() as Map<String, dynamic>;
    final status = data['status'];

    if (status == 'aprobada') {
      _updateUI({'status': 'ok', 'message': 'VISITA APROBADA'});
      setState(() => _isNotifying = false);
      _notificationSub?.cancel();
    } else if (status == 'rechazada') {
      _updateUI({'status': 'error', 'message': 'VISITA RECHAZADA'});
      setState(() => _isNotifying = false);
      _notificationSub?.cancel();
    }
  }

  void _updateUI(Map<String, dynamic> result) {
    if (mounted) {
      setState(() {
        _result = result['message'];
        _isSuccess = result['status'] == 'ok' || result['status'] == 'notificando';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final unannouncedEnabled = widget.state.condoConfig['unannouncedVisitsEnabled'] ?? true;
    final hasTowers = widget.state.towers.isNotEmpty;

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag, 
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Búsqueda de Residente', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),

            if (hasTowers)
              DropdownButtonFormField<String>(
                value: _selectedTower,
                decoration: const InputDecoration(labelText: 'Seleccionar Torre', border: OutlineInputBorder()),
                items: widget.state.towers.map((t) => DropdownMenuItem(value: t, child: Text('Torre $t'))).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedTower = val;
                    _selectedResidentUid = null; 
                  });
                },
              ),
            
            if (hasTowers) const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _selectedResidentUid,
              decoration: const InputDecoration(labelText: 'Seleccionar Unidad/Residente', border: OutlineInputBorder()),
              hint: const Text('Busca por número...'),
              isExpanded: true,
              items: _getFilteredResidents().map((r) {
                return DropdownMenuItem<String>(
                  value: r['uid'],
                  child: Text('${r['fullUnit']} - ${r['nombre']}', overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedResidentUid = val),
            ),

            if (unannouncedEnabled) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              TextFormField(
                controller: _visitorNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Visitante', 
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder()
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: (_isLoading || _isNotifying) ? null : () => _processAction(isNotification: true),
                icon: _isNotifying
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.notifications_active),
                label: Text(_isNotifying ? 'Esperando respuesta...' : 'Notificar Visita'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              ),
            ],

            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: (_isLoading || _isNotifying) ? null : () => _processAction(isNotification: false),
              icon: const Icon(Icons.check),
              label: const Text('Registrar Acceso Manual (Sin aviso)'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            ),

            const SizedBox(height: 24),
            if (_result.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isSuccess ? Colors.green.shade100 : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _result,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: _isSuccess ? Colors.green.shade900 : Colors.red.shade900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}