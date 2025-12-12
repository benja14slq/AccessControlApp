import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminState extends ChangeNotifier {
  
  String? adminUid; 
  String? adminCondoName;
  String? adminCondoTypeId;
  bool isLoadingAdminData = true;
  late DocumentReference _adminDocRef;
  Map<String, dynamic> condoConfig = {};
  
  AdminState() {
  }

  Future<void> loadAdminData() async {
    if (!isLoadingAdminData && adminUid != null) return; 

    isLoadingAdminData = true;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      adminUid = user.uid;

      _adminDocRef = FirebaseFirestore.instance
          .collection('Administradores')
          .doc(adminUid);

      final doc = await _adminDocRef.get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        
        print("Datos del admin cargados en loadAdminData: $data"); 
        
        adminCondoName = data['nombreCondominio'];
        adminCondoTypeId = data['tipoCondominioId'];
        condoConfig = data['configuracion'] ?? {};
      }
    } catch (e) {
      print('Error cargando datos del admin: $e');
    } finally {
      isLoadingAdminData = false;
      notifyListeners();
    }
  }

  Future<void> updateConfig(String key, bool value) async {
    try{
      condoConfig[key] = value;
      notifyListeners();

      await _adminDocRef.update({
        'configuracion.$key': value
      });
    } catch (e) {
      print("Error al actualizar configuración: $e");
      condoConfig[key] = !value;
      notifyListeners();
    }
  }
}