// lib/resident/state/resident_state.dart

import 'dart:async';
import 'package:accesscontrol/shared/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Asegúrate de que mkCode esté disponible
import 'dart:math';
String mkCode() => 'PASS-${Random().nextInt(0xFFFF).toRadixString(16).padLeft(4, '0').toUpperCase()}';

class ResidentState extends ChangeNotifier {
  final String uid;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late final DocumentReference _residentDocRef;

  final List<StreamSubscription> _subscriptions = [];

  // --- DATOS DEL ESTADO ---
  String residentEmail = '';
  String residentName = '';
  String residentLastName = '';
  String condoName = '';
  String condoUnit = '';
  bool hasFaceId = false;
  bool notifEmail = true;
  bool notifPush = true;
  List<Vehicle> vehicles = [];

  // Lista que contendrá SÓLO las visitas futuras programadas (ordenadas)
  List<VisitPass> _upcomingVisitsList = [];

  bool isLoading = true;

  ResidentState({required this.uid}) {
    init();
  }

  // --- MÉTODO DE INICIALIZACIÓN ---
  Future<void> init() async {
    isLoading = true;
    notifyListeners();
    try {
      final query = await _db.collection('Residentes')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();
      if (query.docs.isEmpty) {
        throw Exception("Error Crítico: No se encontró el documento del residente para el UID: $uid");
      }
      _residentDocRef = query.docs.first.reference;
      await _loadAllData();
    } catch (e) {
      print(e.toString());
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // --- MÉTODOS DE CARGA ---
  Future<void> _loadAllData() async {
    isLoading = true;
    notifyListeners();
    try {
      await Future.wait([
        _loadProfile(),
        _loadVehicles(),
        _loadVisits(), // Este ahora carga solo las futuras programadas
      ]);
    } catch (e) {
      print("Error durante la carga inicial de datos: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadProfile() {
    final completer = Completer<void>();
    final sub = _residentDocRef.snapshots().listen(
      (doc) {
        if (!completer.isCompleted) completer.complete();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          residentEmail = data['correo'] ?? '';
          residentName = data['nombre'] ?? '';
          residentLastName = data['apellido'] ?? '';
          condoName = data['nombreCondominio'] ?? '';
          hasFaceId = data['hasFaceId'] ?? false;
          notifEmail = data['notifEmail'] ?? true;
          notifPush = data['notifPush'] ?? true;
          final torre = data['torre'] != null ? 'Torre ${data['torre']}' : '';
          final numero = data['numero'] ?? '';
          condoUnit = '$torre $numero'.trim();
          notifyListeners();
        }
      },
      onError: (error) {
        if (!completer.isCompleted) completer.completeError(error);
        print("Error en stream _loadProfile: $error");
      }
    );
    _subscriptions.add(sub);
    return completer.future;
  }

  Future<void> _loadVehicles() {
    final completer = Completer<void>();
    final sub = _residentDocRef.collection('Vehiculos').snapshots().listen(
      (snapshot) {
        if (!completer.isCompleted) completer.complete();
        vehicles = snapshot.docs.map((doc) {
          return Vehicle(plate: doc.id, alias: doc.data()['alias']);
        }).toList();
        notifyListeners();
      },
      onError: (error) {
         if (!completer.isCompleted) completer.completeError(error);
         print("Error en stream _loadVehicles: $error");
      }
    );
    _subscriptions.add(sub);
    return completer.future;
  }

  // --- _loadVisits CORREGIDO ---
  Future<void> _loadVisits() {
    final completer = Completer<void>();
    final now = DateTime.now(); // Hora actual

    // Consulta específica para visitas futuras programadas
    final sub = _db.collection('Visitas')
        .where('residentUid', isEqualTo: uid)
        .where('status', isEqualTo: 'programada') // Solo las programadas
        .where('scheduledAt', isGreaterThan: Timestamp.now()) // Solo futuras
        .orderBy('scheduledAt', descending: false) // Ordena por más próximas
        .snapshots()
        .listen(
      (snapshot) {
        if (!completer.isCompleted) completer.complete();
        // Guarda directamente en la lista _upcomingVisitsList
        _upcomingVisitsList = snapshot.docs.map((doc) {
          final data = doc.data();
          return VisitPass(
            id: doc.id,
            code: data['code'] ?? 'Error',
            visitorName: data['visitorName'] ?? '',
            // Asume que también guardaste 'visitorLastName'
            // Si no, quita esta línea o ajústala
            // visitorLastName: data['visitorLastName'] ?? '',
            visitorId: data['visitorId'], // RUT
            phone: data['phone'],
            plate: data['plate'],
            scheduledAt: (data['scheduledAt'] as Timestamp).toDate(),
            hostResident: '$residentName $residentLastName',
            status: VisitStatus.programada, // Sabemos que son programadas por la consulta
          );
        }).toList();
        notifyListeners(); // Avisa a la UI que la lista ha cambiado
      },
      onError: (error) {
         if (!completer.isCompleted) completer.completeError(error);
         print("Error en stream _loadVisits: $error");
      }
    );
    _subscriptions.add(sub);
    return completer.future;
  }
  // --- FIN _loadVisits CORREGIDO ---

  // --- MÉTODOS DE ESCRITURA ---
  Future<void> addVehicle(String plate, String? alias) async {
    if (plate.isEmpty) return;
    try {
      await _residentDocRef.collection('Vehiculos').doc(plate.toUpperCase()).set({
        'alias': alias,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) { print('Error al añadir vehículo: $e'); }
  }
  Future<void> removeVehicleAt(int index) async {
    try {
      final plate = vehicles[index].plate;
      await _residentDocRef.collection('Vehiculos').doc(plate).delete();
    } catch (e) { print('Error al eliminar vehículo: $e'); }
  }
  Future<void> createVisit({
    required String visitorName,
    required String visitorLastName,
    String? rut,
    String? phone,
    String? plate,
    required DateTime scheduledAt,
  }) async {
    try {
      final doc = await _residentDocRef.get();
      final adminUid = (doc.data() as Map<String, dynamic>)['adminUid'];

      await _db.collection('Visitas').add({
        'residentUid': uid,
        'adminUid': adminUid,
        'visitorName': visitorName,
        'visitorLastName': visitorLastName,
        'visitorId': rut,
        'phone': phone,
        'plate': plate?.toUpperCase(),
        'scheduledAt': Timestamp.fromDate(scheduledAt),
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'programada',
        'code': 'PASS-${mkCode().substring(5)}',
      });
      // No necesitas hacer nada más, el listener de _loadVisits actualizará la lista
    } catch (e) {
      print('Error al crear visita: $e');
      // Re-lanza para mostrar en UI si quieres
      // throw Exception('No se pudo crear la visita.');
    }
  }
  Future<void> toggleFaceId() async { await _residentDocRef.update({'hasFaceId': !hasFaceId}); }
  Future<void> setNotifEmail(bool v) async { notifEmail = v; notifyListeners(); await _residentDocRef.update({'notifEmail': v}); }
  Future<void> setNotifPush(bool v) async { notifPush = v; notifyListeners(); await _residentDocRef.update({'notifPush': v}); }


  // --- GETTERS SIMPLIFICADOS ---

  /// Retorna la lista completa de visitas futuras programadas (ya filtrada y ordenada)
  List<VisitPass> get upcomingVisits {
    return _upcomingVisitsList;
  }

  /// Retorna el conteo de visitas programadas para HOY (que aún no ocurren)
  int get visitsTodayCount {
    final now = DateTime.now();
    // Final del día de hoy
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    // Filtra la lista _upcomingVisitsList (que ya son futuras y programadas)
    return _upcomingVisitsList.where((v) =>
        v.scheduledAt.isBefore(endOfDay) // Asegura que sea hoy
    ).length;
  }

  @override
  void dispose() {
    for (var sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }
}