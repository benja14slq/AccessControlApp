// lib/state/app_state.dart

import 'package:accesscontrol/admin/state/admin_state.dart';
// Ya no importamos los estados de residente o guardia aquí
import 'package:accesscontrol/shared/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  
  // AppState ahora solo maneja estados globales, no específicos del usuario
  final AdminState adminState;

  List<CondoType> condoTypes = [];
  bool isLoadingTypes = true;

  AppState() 
    : adminState = AdminState() { // AdminState se carga a sí mismo
        
    adminState.addListener(notifyListeners);

    // Llama a la función para cargar los tipos
    _fetchCondoTypes();
  }

  // Función que carga los datos desde Firestore
  Future<void> _fetchCondoTypes() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('condo_types')
          .orderBy('order')
          .get();

      condoTypes = querySnapshot.docs
          .map((doc) => CondoType.fromFirestore(doc.data(), doc.id))
          .toList();

    } catch (e) {
      print("Error cargando tipos de condominio: $e");
    } finally {
      isLoadingTypes = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    adminState.removeListener(notifyListeners);
    super.dispose();
  }
}