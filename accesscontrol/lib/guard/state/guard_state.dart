import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:accesscontrol/shared/api_constants.dart';
import 'package:accesscontrol/shared/models.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // IMPORTANTE para usar compute()
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

// 🚀 FUNCIÓN AISLADA (ISOLATE): Procesa la imagen en un núcleo secundario del procesador
// Esto evita que la pantalla se congele al procesar fotos de alta resolución.
String _processImageToBase64(String path) {
  final bytes = File(path).readAsBytesSync();
  return base64Encode(bytes);
}

class GuardState extends ChangeNotifier {
  final String uid;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  late final DocumentReference _guardDocRef;
  
  String? _condominioId; 
  String? _guardFullName;

  final List<StreamSubscription> _subscriptions = [];

  List<AccessEvent> events = [];
  List<Map<String, dynamic>> residentsList = []; 
  List<String> towers = [];
  
  Map<String, dynamic> condoConfig = {};
  bool isLoading = true;

  String get condominioId => _condominioId ?? '';
  String get guardFullName => _guardFullName ?? 'Guardia';

  GuardState({required this.uid}) {
    _db.settings = const Settings(persistenceEnabled: true);
  }

  Future<void> init() async {
    isLoading = true;
    notifyListeners();
    try {
      final query = await _db.collection('Guardias').where('uid', isEqualTo: uid).limit(1).get();
      if (query.docs.isEmpty) throw Exception('Perfil de guardia no encontrado para el UID: $uid');
      
      final guardDoc = query.docs.first;
      final guardData = guardDoc.data(); 
      
      _guardDocRef = guardDoc.reference; 
      _condominioId = guardData['condominioId']; 
      _guardFullName = '${guardData['nombre']} ${guardData['apellido']}';

      if (_condominioId != null) {
        _loadEvents();
        _loadConfig();
        await _loadResidentsForDropdowns(); 
      }
    } catch (e) {
      print('Error Crítico en GuardState init: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadResidentsForDropdowns() async {
    if (_condominioId == null) return;
    try {
      final snapshot = await _db.collection('Residentes').where('condominioId', isEqualTo: _condominioId).get();
      
      residentsList = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'uid': data['uid'], 
          'nombre': '${data['nombre']} ${data['apellido']}',
          'torre': data['torre'] ?? '',
          'numero': data['numero'] ?? '',
          'fullUnit': '${data['torre'] != null ? "${data['torre']} - " : ""}${data['numero']}'
        };
      }).toList();

      final towerSet = <String>{};
      for (var r in residentsList) {
        if (r['torre'].toString().isNotEmpty) towerSet.add(r['torre']);
      }
      towers = towerSet.toList()..sort();
      notifyListeners();
    } catch (e) {
      print("Error cargando residentes: $e");
    }
  }

  void _loadEvents() {
    if (_condominioId == null) return;
    final sub = _db.collection('Eventos')
        .where('condominioId', isEqualTo: _condominioId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
          events = snapshot.docs.map((doc) => AccessEvent.fromFirestore(doc)).toList();
          notifyListeners();
        });
    _subscriptions.add(sub);
  }

  void _loadConfig() {
    if (_condominioId == null) return;
    final sub = _db.collection('Condominios').doc(_condominioId).snapshots().listen((doc) {
      if (doc.exists) {
        condoConfig = (doc.data() as Map<String, dynamic>)['configuracion'] ?? {};
        notifyListeners();
      }
    });
    _subscriptions.add(sub);
  }

  // ==========================================
  // VERIFICACIÓN FACIAL (OPTIMIZADA)
  // ==========================================
  Future<Map<String, dynamic>> verifyFaceByImage() async {
    if (_condominioId == null) throw Exception("Error de inicialización.");

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 85, // Calidad alta
        maxWidth: 1920,   // Resolución Full HD (Suficiente para AWS, evita crashear la RAM)
      );

      if (photo == null) throw Exception('Captura cancelada.');

      // ⏱️ TIEMPO DE RESPIRACIÓN: Esperamos que la cámara nativa se cierre por completo
      await Future.delayed(const Duration(milliseconds: 600));
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      // 🚀 ISOLATE: Convertimos la imagen pesada en segundo plano
      final String base64Image = await compute(_processImageToBase64, photo.path);

      // LLAMADA A AWS
      final Uri verifyUrl = Uri.parse('$apiGatewayUrl/verify');
      final response = await http.post(
        verifyUrl,
        headers: { 'Content-Type': 'application/json', 'x-api-key': apiKey },
        body: jsonEncode({ 'imageBase64': base64Image }),
      );

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Error del servidor');
      }

      final data = jsonDecode(response.body);
      if (data['match'] == false || data['faceId'] == null) throw Exception('ROSTRO NO RECONOCIDO.');
      
      final String faceId = data['faceId'];
      final double similarity = data['similarity'];

      // BÚSQUEDA EN FIRESTORE
      final residentQuery = await _db.collection('Residentes')
          .where('condominioId', isEqualTo: _condominioId)
          .where('rekognitionFaceId', isEqualTo: faceId)
          .limit(1)
          .get();

      DocumentSnapshot? docEncontrado;
      String tipoMiembro = "Residente";
      DocumentReference? residentRef;

      if (residentQuery.docs.isNotEmpty) {
        docEncontrado = residentQuery.docs.first;
        residentRef = docEncontrado.reference;
      } else {
        final familyQuery = await _db.collectionGroup('GrupoFamiliar')
            .where('rekognitionFaceId', isEqualTo: faceId)
            .limit(1)
            .get();

        if (familyQuery.docs.isNotEmpty) {
          docEncontrado = familyQuery.docs.first;
          tipoMiembro = "Grupo Familiar";
          residentRef = docEncontrado.reference.parent.parent;
        }
      }

      if (docEncontrado == null || residentRef == null) throw Exception('Rostro no asociado a residente.');

      final personData = docEncontrado.data() as Map<String, dynamic>;
      final String personName = '${personData['nombre']} ${personData['apellido']}';

      final residentDoc = await residentRef.get();
      if (!residentDoc.exists) throw Exception('Residente principal no encontrado');

      final residentData = residentDoc.data() as Map<String, dynamic>;
      final String unit = residentData['torre'] != null
          ? 'Torre ${residentData['torre']} - ${residentData['numero']}'
          : 'Nº ${residentData['numero']}';

      await _logEvent(
        description: 'Ingreso facial: $personName ($tipoMiembro)\nUnidad: $unit (Sim: ${similarity.toStringAsFixed(1)}%)', 
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
      await _logEvent(description: 'Ingreso facial rechazado: ${e.toString()}', status: 'rechazada_facial');
      return {
        'success': false,
        'message': e.toString().contains('Exception:') ? e.toString().split(': ')[1] : e.toString()
      };
    }
  }

  // ==========================================
  // VERIFICACIÓN LPR PATENTE (OPTIMIZADA)
  // ==========================================
  Future<Map<String, dynamic>> verifyPlateByLPR() async {
    if (_condominioId == null) throw Exception("Error de inicialización");
    String recognizedPlate = '';
    
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85,
        maxWidth: 1920, // Resolución alta para leer patente clara
      );
      if (photo == null) throw Exception('Captura cancelada.');

      // ⏱️ TIEMPO DE RESPIRACIÓN
      await Future.delayed(const Duration(milliseconds: 600));
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      // PROCESAMIENTO ML KIT
      final inputImage = InputImage.fromFilePath(photo.path);
      final textRecognizer = TextRecognizer();
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

      String bestMatch = '';
      final regex = RegExp(r'^[A-Z]{2}[A-Z0-9]{2}[0-9]{2}$'); // Regex Patente Chilena
      
      for (TextBlock block in recognizedText.blocks) {
        String text = block.text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
        if (regex.hasMatch(text)) {
          bestMatch = text;
          break;
        } else if (text.length == 6) {
          bestMatch = text; // Fallback
        }
      }
      textRecognizer.close();

      if (bestMatch.isEmpty) throw Exception('No se pudo leer una patente válida.');
      recognizedPlate = bestMatch;

      // BÚSQUEDA FIRESTORE
      final vehicleQuery = await _db.collectionGroup('Vehiculos')
          .where('condominioId', isEqualTo: _condominioId)
          .where('plate', isEqualTo: recognizedPlate)
          .limit(1)
          .get();

      if (vehicleQuery.docs.isEmpty) throw Exception('PATENTE NO REGISTRADA: $recognizedPlate');

      final vehicleDoc = vehicleQuery.docs.first;
      final residentRef = vehicleDoc.reference.parent.parent;
      
      if (residentRef == null) throw Exception('Vehículo sin residente.');
      final residentDoc = await residentRef.get();
      final residentData = residentDoc.data() as Map<String, dynamic>;

      final String residentName = '${residentData['nombre']} ${residentData['apellido']}';
      final String unit = residentData['torre'] != null
          ? 'Torre ${residentData['torre']} - ${residentData['numero']}'
          : 'Nº ${residentData['numero']}';

      await _logEvent(
        description: 'Ingreso LPR: $residentName (Patente: $recognizedPlate)', 
        status: 'autorizada_lpr',
        residentUid: residentData['uid'],
        residentName: residentName,
        residentTower: residentData['torre'],
        residentUnit: residentData['numero'],
      );
      
      return {
        'success': true,
        'message': 'ACCESO AUTORIZADO:\n$residentName\n$unit (Patente: $recognizedPlate)'
      };

    } catch (e) {
      await _logEvent(description: 'Rechazo LPR: ${e.toString()} ($recognizedPlate)', status: 'rechazada_lpr');
      return {
        'success': false,
        'message': e.toString().contains('Exception:') ? e.toString().split(': ')[1] : e.toString()
      };
    }
  }

  // ==========================================
  // VERIFICACIÓN QR Y EXTRAS
  // ==========================================
  Future<String> verifyPass(String code) async {
    if (_condominioId == null) throw Exception("Error de inicialización");

    try {
      final query = await _db.collection('Visitas')
          .where('condominioId', isEqualTo: _condominioId)
          .where('code', isEqualTo: code)
          .where('status', isEqualTo: 'programada')
          .where('scheduledAt', isGreaterThan: Timestamp.now())
          .limit(1)
          .get();

      if (query.docs.isEmpty) throw Exception('Pase expirado, inválido o de otro condominio.');

      final visitDoc = query.docs.first;
      final visitData = visitDoc.data();
      
      final String residentUid = visitData['residentUid'];
      String residentName = 'Desconocido';
      String? residentTower;
      String? residentUnit;

      final residentLocal = residentsList.firstWhere((r) => r['uid'] == residentUid, orElse: () => {});
      if (residentLocal.isNotEmpty) {
         residentName = residentLocal['nombre'];
         residentTower = residentLocal['torre']?.toString();
         residentUnit = residentLocal['numero']?.toString();
      }

      await visitDoc.reference.update({
        'status': 'autorizada',
        'checkedByGuardUid': uid,
        'checkedAt': FieldValue.serverTimestamp(),
      });
      
      await _logEvent(
        description: 'Ingreso QR: ${visitData['visitorName']} (Pase: $code)', 
        status: 'autorizada_qr',
        residentUid: residentUid,
        residentName: residentName,
        residentTower: residentTower,
        residentUnit: residentUnit,
      );
      
      return 'PASE AUTORIZADO:\n${visitData['visitorName']}';
      
    } catch (e) {
      await _logEvent(description: 'QR rechazado: $code', status: 'rechazada_qr');
      throw Exception('Error al verificar: $e');
    }
  }

  Future<Map<String, dynamic>> notifyOrLogManual({
    required String residentUid,
    required String residentName,
    String? visitorName,
    String? torre,
    String? numero,
  }) async {
    if (_condominioId == null) return {'status': 'error', 'message': 'Error de inicialización'};

    try {
      if (visitorName != null && visitorName.isNotEmpty) {
        final newNotification = await _db.collection('notificaciones_visita').add({
          'condominioId': _condominioId, 
          'guardUid': uid,
          'guardName': _guardFullName,
          'residentUid': residentUid,
          'residentName': residentName,
          'visitorName': visitorName,
          'status': 'pendiente',
          'createdAt': FieldValue.serverTimestamp(),
          'torre': torre,
          'numero': numero,
        });

        return {'status': 'notificando', 'docId': newNotification.id, 'message': 'Notificando a $residentName...'};
      } else {
        await _logEvent(
          description: 'Acceso manual: $residentName', 
          status: 'autorizada_manual',
          residentUid: residentUid,
          residentName: residentName,
          residentTower: torre,
          residentUnit: numero,
        );
        return {'status': 'ok', 'message': 'ACCESO REGISTRADO:\n$residentName'};
      }
    } catch (e) {
       return {'status': 'error', 'message': e.toString()};
    }
  }

  Future<void> _logEvent({
    required String description, 
    required String status,
    String? residentUid,
    String? residentName,
    String? residentTower,
    String? residentUnit,
  }) async {
    if (_condominioId == null) return;
    try {
      await _db.collection('Eventos').add({
        'condominioId': _condominioId, 
        'guardUid': uid,
        'description': description,
        'status': status,
        'timestamp': FieldValue.serverTimestamp(),
        'residentUid': residentUid,
        'residentName': residentName,
        'residentTower': residentTower,
        'residentUnit': residentUnit,
      });
    } catch (e) {
      print("Error log: $e");
    }
  }

  @override
  void dispose() {
    for (var sub in _subscriptions) sub.cancel();
    super.dispose();
  }
}