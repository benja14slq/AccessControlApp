import 'dart:async';
import 'package:accesscontrol/shared/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:accesscontrol/shared/api_constants.dart';

class GuardState extends ChangeNotifier{
  final String uid;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late final DocumentReference _guardDocRef;
  late String _adminUid;
  late String _guardFullName;

  final List<StreamSubscription> _subscriptions = [];

  List<AccessEvent> events = [];
  bool isLoading = true;

  String get adminUid => _adminUid;

  GuardState({required this.uid});

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

  Future<void> _loadEvents() {
    final completer = Completer<void>();
    final sub = _db.collection('Eventos')
        .where('adminUid', isEqualTo: _adminUid)
        .orderBy('timestamp', descending: true)
        .limit(100)
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

  Future<String> verifyPass(String code) async {
    try {
      final query = await _db.collection('Visitas')
          .where('code', isEqualTo: code.toUpperCase())
          .where('adminUid', isEqualTo: _adminUid) 
          .where('status', isEqualTo: 'programada')
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        throw Exception('CÓDIGO INVÁLIDO O EXPIRADO');
      }

      final visitDoc = query.docs.first;
      final data = visitDoc.data();

      final String residentUid = data['residentUid'];
      String residentName = 'N/A';
      String? residentTower;
      String? residentUnit;
      try {
        final residentDoc = await _db.collection('Residentes').doc(residentUid).get();
        if (residentDoc.exists) {
          final resData = residentDoc.data()!;
          residentName = '${resData['nombre']} ${resData['apellido']}';
          residentTower = resData['torre'];
          residentUnit = resData['numero'];
        }
      } catch (e) { /* Ignorar error si no se encuentra el residente */ }

      await visitDoc.reference.update({
        'status': 'autorizada',
        'checkedByGuardUid': uid,
      });
      
      final description = 'Ingreso autorizado: ${data['visitorName']} (Pase: $code)';
      await _logEvent(
        description: description, 
        status: 'autorizada_qr',
        residentUid: residentUid,
        residentName: residentName,
        residentTower: residentTower,
        residentUnit: residentUnit,
      );
      
      return 'PASE AUTORIZADO:\n${data['visitorName']}';
      
    } catch (e) {
      final description = 'Ingreso rechazado. Código: $code';
      await _logEvent(description: description, status: 'rechazada');
      return e.toString().contains('Exception:') ? e.toString().split(': ')[1] : e.toString();
    }
  }

  Future<Map<String, dynamic>> verifyFaceByImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 80,
        maxWidth: 1080,
      );

      if (photo == null) {
        throw Exception('Captura cancelada.');
      }

      final bytes = await File(photo.path).readAsBytes();
      final String base64Image = base64Encode(bytes);

      final Uri verifyUrl = Uri.parse('$apiGatewayUrl/verify');
      
      final response = await http.post(
        verifyUrl,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
        },
        body: jsonEncode({
          'imageBase64': base64Image,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Error del servidor: ${response.body}');
      }

      final data = jsonDecode(response.body);
      
      if (data['match'] == false || data['faceId'] == null) {
        throw Exception('ROSTRO NO RECONOCIDO.');
      }
      
      final String faceId = data['faceId'];
      final double similarity = data['similarity'];

      final residentQuery = await _db.collection('Residentes')
          .where('adminUid', isEqualTo: _adminUid) 
          .where('rekognitionFaceId', isEqualTo: faceId)
          .limit(1)
          .get();

      DocumentSnapshot? docEncontrado;
      String tipoMiembro = "Residente";
      DocumentReference? residenteDocRef;

      if (residentQuery.docs.isNotEmpty) {
        docEncontrado = residentQuery.docs.first;
        residenteDocRef = docEncontrado.reference;
      } else {
        // 2. Si no lo encuentra, busca en las sub-colecciones 'GrupoFamiliar'
        final familyQuery = await _db.collectionGroup('GrupoFamiliar')
            .where('rekognitionFaceId', isEqualTo: faceId)
            .limit(1)
            .get();

        if (familyQuery.docs.isNotEmpty) {
          docEncontrado = familyQuery.docs.first;
          tipoMiembro = "Grupo Familiar";
          residenteDocRef = docEncontrado.reference.parent.parent;
        }
      }

      if (docEncontrado == null || residenteDocRef == null) {
        throw Exception('Rostro reconocido, pero no asociado a este condominio.');
      }

      final personData = docEncontrado.data() as Map<String, dynamic>;
      final String personName = '${personData['nombre']} ${personData['apellido']}';

      final residentDoc = await residenteDocRef.get();
      final residentData = residentDoc.data() as Map<String, dynamic>;
      final String unit = residentData['torre'] != null
          ? 'Torre ${residentData['torre']} - ${residentData['numero']}'
          : 'Nº ${residentData['numero']}';

      final description = 'Ingreso facial: $personName ($tipoMiembro)';
      
      await _logEvent(
        description: description, 
        status: 'autorizada_facial',
        residentUid: residentData['uid'],
        residentName: '${residentData['nombre']} ${residentData['apellido']}',
        residentTower: residentData['torre'],
        residentUnit: residentData['numero'],
      );
      
      return {
        'success': true,
        'message': 'ACCESO AUTORIZADO:\n$personName ($tipoMiembro)\n$unit'
      };

    } catch (e) {
      final description = 'Ingreso facial rechazado: ${e.toString()}';
      await _logEvent(description: description, status: 'rechazada_facial');
      return {
        'success': false,
        'message': e.toString().contains('Exception:') ? e.toString().split(': ')[1] : e.toString()
      };
    }
  }

  // --- 4. LÓGICA DE ACCESO MANUAL ---
  Future<void> triggerManualAccess(String gateName) async {
    final description = 'Apertura manual: $gateName (Por: $_guardFullName)';
    await _logEvent(description: description, status: 'manual');
  }

  // --- 5. FUNCIÓN INTERNA PARA BITÁCORA ---
  Future<void> _logEvent({
    required String description, 
    required String status,
    String? residentUid,
    String? residentName,
    String? residentTower,
    String? residentUnit,
  }) async {
    try {
      await _db.collection('Eventos').add({
        'adminUid': _adminUid,
        'guardUid': uid,
        'description': description,
        'status': status,
        'timestamp': FieldValue.serverTimestamp(),
        // --- NUEVOS CAMPOS PARA FILTROS ---
        'residentUid': residentUid,
        'residentName': residentName,
        'residentTower': residentTower,
        'residentUnit': residentUnit,
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