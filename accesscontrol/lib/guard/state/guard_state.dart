import 'dart:async';
import 'package:accesscontrol/shared/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class GuardState extends ChangeNotifier{
  final String uid;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late final DocumentReference _guardDocRef;
  late String _adminUid;
  late String _guardFullName;

  final List<StreamSubscription> _subscriptions = [];

  List<AccessEvent> events = [];
  bool isLoading = true;

  GuardState({required this.uid});

  // --- 1. INICIALIZACIÓN ---
  Future<void> init() async {
    isLoading = true;
    notifyListeners();
    try {
      final query = await _db.collection('Guardias')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();
      
      if (query.docs.isEmpty) {
        throw Exception("Error Crítico: No se encontró el documento del Guardia para el UID: $uid");
      }
      _guardDocRef = query.docs.first.reference;
      final data = query.docs.first.data();
      
      // Guardamos datos importantes del guardia
      _adminUid = data['adminUid'];
      _guardFullName = '${data['nombre']} ${data['apellido']}';
      
      await _loadEvents();

    } catch (e) {
      print(e.toString());
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // --- 2. CARGA DE DATOS (BITÁCORA) ---
  Future<void> _loadEvents() {
    final completer = Completer<void>();
    // Escuchamos la colección de Eventos, filtrada por el admin
    final sub = _db.collection('Eventos')
        .where('adminUid', isEqualTo: _adminUid)
        .orderBy('timestamp', descending: true)
        .limit(100) // Trae los 100 eventos más recientes
        .snapshots()
        .listen((snapshot) {
      
      if (!completer.isCompleted) completer.complete();
      events = snapshot.docs.map((doc) {
        final data = doc.data();
        return AccessEvent(
          description: data['description'],
          timestamp: (data['timestamp'] as Timestamp).toDate(),
        );
      }).toList();
      notifyListeners();
      
    }, onError: (e) {
      if (!completer.isCompleted) completer.completeError(e);
      print("Error cargando bitácora: $e");
    });

    _subscriptions.add(sub);
    return completer.future;
  }
  
  // --- 3. LÓGICA DE VERIFICACIÓN (CONECTADA A FIRESTORE) ---
  Future<String> verifyPass(String code) async {
    try {
      // 1. Busca el pase en la colección 'Visitas'
      final query = await _db.collection('Visitas')
          .where('code', isEqualTo: code.toUpperCase())
          .where('adminUid', isEqualTo: _adminUid) // Importante: solo visitas de este condominio
          .where('status', isEqualTo: 'programada')
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        throw Exception('CÓDIGO INVÁLIDO O EXPIRADO');
      }

      final visitDoc = query.docs.first;
      final data = visitDoc.data();

      // 2. Si lo encuentra, actualiza el estado en Firestore
      await visitDoc.reference.update({
        'status': 'autorizada',
        'checkedByGuardUid': uid, // Opcional: guarda qué guardia lo aprobó
      });
      
      // 3. Crea un evento en la bitácora
      final description = 'Ingreso autorizado: ${data['visitorName']} (Pase: $code)';
      await _logEvent(description: description, status: 'autorizada');
      
      return 'PASE AUTORIZADO:\n${data['visitorName']}';
      
    } catch (e) {
      // 4. Si falla, registra el evento y retorna el error
      final description = 'Ingreso rechazado. Código: $code';
      await _logEvent(description: description, status: 'rechazada');
      return e.toString().contains('Exception:') ? e.toString().split(': ')[1] : e.toString();
    }
  }

  // --- 4. LÓGICA DE ACCESO MANUAL ---
  Future<void> triggerManualAccess(String gateName) async {
    final description = 'Apertura manual: $gateName (Por: $_guardFullName)';
    await _logEvent(description: description, status: 'manual');
  }

  // --- 5. FUNCIÓN INTERNA PARA BITÁCORA ---
  Future<void> _logEvent({required String description, required String status}) async {
    try {
      await _db.collection('Eventos').add({
        'adminUid': _adminUid,
        'guardUid': uid,
        'description': description,
        'status': status,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error al guardar evento: $e");
    }
  }

  @override
  void dispose() {
    for (var sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }
}