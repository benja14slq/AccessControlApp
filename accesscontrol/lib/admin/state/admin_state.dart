import 'package:accesscontrol/shared/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminState extends ChangeNotifier {
  String? adminUid;
  String? currentCondominioId;
  String? adminCondoName;
  String? adminCondoTypeId;

  List<Condominio> availableCondos = [];
  bool isLoadingAdminData = true;
  
  late DocumentReference _adminDocRef;
  DocumentReference? _condoDocRef;
  
  Map<String, dynamic> condoConfig = {};

  AdminState();

  Future<void> loadAdminData() async {
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

      final adminDoc = await _adminDocRef.get();

      if (adminDoc.exists) {
        final adminData = adminDoc.data() as Map<String, dynamic>;
        
        List<String> condominiosIds = List<String>.from(adminData['condominiosIds'] ?? []);
        
        if (condominiosIds.isNotEmpty) {
          final condosSnap = await FirebaseFirestore.instance
              .collection('Condominios')
              .where(FieldPath.documentId, whereIn: condominiosIds)
              .get();

          availableCondos = condosSnap.docs
              .map((doc) => Condominio.fromFirestore(doc))
              .toList();

          if (availableCondos.length == 1) {
            await selectCondominio(availableCondos.first);
          }
        } else {
          print('Advertencia: El administrador no tiene condominios asociados.');
        }
      }
    } catch (e) {
      print('Error crítico cargando datos del administrador: $e');
    } finally {
      isLoadingAdminData = false;
      notifyListeners();
    }
  }

  Future<void> selectCondominio(Condominio condo) async {
    currentCondominioId = condo.id;
    adminCondoName = condo.nombreCondominio;
    adminCondoTypeId = condo.tipoCondominioID;
    condoConfig = condo.configuracion;
    
    _condoDocRef = FirebaseFirestore.instance
        .collection('Condominios')
        .doc(currentCondominioId);
        
    notifyListeners();
  }

  void clearSelection() {
    currentCondominioId = null;
    adminCondoName = null;
    adminCondoTypeId = null;
    condoConfig = {};
    _condoDocRef = null;
    notifyListeners();
  }

  Future<void> updateConfig(String key, bool value) async {
    if (_condoDocRef == null) return;

    try {
      condoConfig[key] = value;
      notifyListeners();

      await _condoDocRef!.update({
        'configuracion.$key': value
      });
    } catch (e) {
      print("Error al actualizar configuración en la nube: $e");
      
      condoConfig[key] = !value;
      notifyListeners();
      
      rethrow;
    }
  }

  Future<void> createAndLinkNewCondominio(String nombre, String tipoId) async {
    if (adminUid == null) return;

    try {
      final newCondoRef = FirebaseFirestore.instance.collection('Condominios').doc();
      
      final condoData = {
        'nombreCondominio': nombre,
        'tipoCondominioID': tipoId,
        'configuracion': {
          'biometria_activa': false, 
          'lpr_activo': false,
        },
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      await newCondoRef.set(condoData);

      await _adminDocRef.update({
        'condominiosIds': FieldValue.arrayUnion([newCondoRef.id])
      });

      await loadAdminData();

    } catch (e) {
      print("Error al crear un nuevo condominio: $e");
      rethrow;
    }
  }
}