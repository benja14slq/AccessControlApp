// lib/state/app_state.dart

import 'package:accesscontrol/admin/state/admin_state.dart';
import 'package:accesscontrol/guard/state/guard_state.dart';
import 'package:accesscontrol/resident/state/resident_state.dart';
import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  
  final ResidentState residentState;
  final AdminState adminState;
  late final GuardState guardState; // <-- Se marca como 'late final'

  // Constructor
  AppState() 
    // 1. Inicializa los estados que NO tienen dependencias
    : residentState = ResidentState(),
      adminState = AdminState() {
        
    // 2. Ahora, EN EL CUERPO, inicializa el estado que SÍ depende de otro
    guardState = GuardState(residentState: residentState);
        
    // 3. Agrega los listeners
    residentState.addListener(notifyListeners);
    adminState.addListener(notifyListeners);
    guardState.addListener(notifyListeners);
  }

  @override
  void dispose() {
    residentState.removeListener(notifyListeners);
    adminState.removeListener(notifyListeners);
    guardState.removeListener(notifyListeners);
    super.dispose();
  }
}