// lib/admin/state/admin_state.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminState extends ChangeNotifier {
  
  // DATOS DEL ADMIN LOGUEADO
  String? adminUid; // <-- CAMBIO: Guardamos el UID
  String? adminCondoName;
  String? adminCondoTypeId;
  bool isLoadingAdminData = true;
  
  AdminState() {
  }

  Future<void> loadAdminData() async {
    // Si ya está cargado, no lo hagas de nuevo (opcional)
    if (!isLoadingAdminData && adminUid != null) return; 

    isLoadingAdminData = true;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      adminUid = user.uid;

      final doc = await FirebaseFirestore.instance
          .collection('Administradores')
          .doc(adminUid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        
        // --- Debug Print (puedes borrar esto después) ---
        print("Datos del admin cargados en loadAdminData: $data"); 
        // ---------------------------------------------
        
        adminCondoName = data['nombreCondominio'];
        adminCondoTypeId = data['tipoCondominioId'];
      }
    } catch (e) {
      print('Error cargando datos del admin: $e');
    } finally {
      isLoadingAdminData = false;
      notifyListeners();
    }
  }
}