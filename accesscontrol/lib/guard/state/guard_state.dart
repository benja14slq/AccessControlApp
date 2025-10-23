// lib/guard/state/guard_state.dart

import 'package:accesscontrol/resident/state/resident_state.dart';
import 'package:accesscontrol/shared/models.dart';
import 'package:flutter/material.dart';

class GuardState extends ChangeNotifier {
  // El estado del guardia necesita acceso a las visitas creadas por los residentes
  final ResidentState residentState;
  
  GuardState({required this.residentState});

  // Lista de eventos para la bitácora
  final List<AccessEvent> events = [];

  // Simulación de verificación de pase
  String verifyPass(String code) {
    try {
      // 1. Busca el pase en la lista del residente
      final pass = residentState.visits.firstWhere(
        (v) => v.code == code.toUpperCase() && v.status == VisitStatus.programada
      );

      // 2. Si lo encuentra, actualiza el estado (simulación)
      pass.status = VisitStatus.autorizada;
      
      // 3. Crea un evento en la bitácora
      final event = AccessEvent(
        description: 'Ingreso autorizado: ${pass.visitorName} (Visita a ${pass.hostResident}). Código: $code',
        timestamp: DateTime.now(),
      );
      events.insert(0, event);
      
      // 4. Notifica a los listeners (la UI del Guardia y del Residente)
      notifyListeners();
      residentState.notifyListeners(); // Avisa al residente que su visita se autorizó
      
      return 'PASE AUTORIZADO:\n${pass.visitorName}\nDestino: ${pass.hostResident}';
      
    } catch (e) {
      // 5. Si no lo encuentra (o el estado no es 'programada'), lo rechaza
      final event = AccessEvent(
        description: 'Ingreso rechazado. Código: $code',
        timestamp: DateTime.now(),
      );
      events.insert(0, event);
      notifyListeners();
      return 'CÓDIGO INVÁLIDO O EXPIRADO';
    }
  }

  // Simulación de apertura manual de puertas
  void triggerManualAccess(String gateName) {
     final event = AccessEvent(
        description: 'Apertura manual: $gateName',
        timestamp: DateTime.now(),
      );
      events.insert(0, event);
      notifyListeners();
  }
}