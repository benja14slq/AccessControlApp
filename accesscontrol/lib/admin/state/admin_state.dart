import 'package:accesscontrol/shared/models.dart';
import 'package:flutter/material.dart';

class AdminState extends ChangeNotifier {
  
  // Lista de todos los usuarios registrados en el condominio
  final List<CondoUser> users = [];
  
  // Datos de maqueta
  AdminState() {
    users.addAll([
      CondoUser(email: 'residente@condo.cl', role: 'Residente', unit: 'Depto 101', registered: true),
      CondoUser(email: 'guardia_dia@condo.cl', role: 'Guardia', unit: 'Turno Día', registered: true),
      CondoUser(email: 'vecino_nuevo@gmail.com', role: 'Residente', unit: 'Depto 202', registered: false),
    ]);
  }

  // Lógica de invitación
  void inviteResident(String email, String unit) {
    if (email.isEmpty || unit.isEmpty) return;
    users.insert(0, CondoUser(email: email, role: 'Residente', unit: unit, registered: false));
    notifyListeners();
  }

  void inviteGuard(String email, String unit) {
    if (email.isEmpty || unit.isEmpty) return;
    users.insert(0, CondoUser(email: email, role: 'Guardia', unit: unit, registered: false));
    notifyListeners();
  }
  
  void revokeAccess(int index) {
      users.removeAt(index);
      notifyListeners();
  }
}