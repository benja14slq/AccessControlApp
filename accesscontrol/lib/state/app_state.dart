import 'package:accesscontrol/admin/state/admin_state.dart';
import 'package:accesscontrol/shared/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  
  final AdminState adminState;

  List<CondoType> condoTypes = [];
  bool isLoadingTypes = true;

  AppState() 
    : adminState = AdminState() { 
        
    adminState.addListener(notifyListeners);

    _fetchCondoTypes();
  }

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