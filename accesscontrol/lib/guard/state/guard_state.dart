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

  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

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
      final query = await _db
          .collection('Guardias')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();
      if (query.docs.isEmpty)
        throw Exception('Perfil de guardia no encontrado para el UID: $uid');

      final guardDoc = query.docs.first;
      final guardData = guardDoc.data();

      _guardDocRef = guardDoc.reference;
      _condominioId = guardData['condominioId'];
      _guardFullName = '${guardData['nombre']} ${guardData['apellido']}';

      if (_condominioId != null) {
        loadEventsByDate(DateTime.now());
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
      final snapshot = await _db
          .collection('Residentes')
          .where('condominioId', isEqualTo: _condominioId)
          .get();

      residentsList = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'uid': data['uid'],
          'nombre': '${data['nombre']} ${data['apellido']}',
          'torre': data['torre'] ?? '',
          'numero': data['numero'] ?? '',
          'fullUnit':
              '${data['torre'] != null ? "${data['torre']} - " : ""}${data['numero']}',
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

  void loadEventsByDate(DateTime date) {
    if (_condominioId == null) return;
    _selectedDate = date;

    // Limpiamos los eventos anteriores mientras carga
    events = [];
    notifyListeners();

    // Calculamos el inicio y fin del día seleccionado
    final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    // Cancelamos la suscripción anterior para no dejar procesos fantasmas (cobran dinero)
    if (_subscriptions.isNotEmpty) {
      _subscriptions.last.cancel();
      _subscriptions.removeLast();
    }

    // Consulta optimizada a Firebase
    final sub = _db
        .collection('Eventos')
        .where('condominioId', isEqualTo: _condominioId)
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('timestamp', descending: true)
        .limit(100) // Limite de seguridad
        .snapshots()
        .listen((snapshot) {
          events = snapshot.docs
              .map((doc) => AccessEvent.fromFirestore(doc))
              .toList();
          notifyListeners();
        });

    _subscriptions.add(sub);
  }

  void _loadConfig() {
    if (_condominioId == null) return;
    final sub = _db
        .collection('Condominios')
        .doc(_condominioId)
        .snapshots()
        .listen((doc) {
          if (doc.exists) {
            condoConfig =
                (doc.data() as Map<String, dynamic>)['configuracion'] ?? {};
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
      try {
        // 1. EL SECRETO: Añadimos un ".timeout". Si en 3 segundos no hay red, salta el error de inmediato.
        final result = await InternetAddress.lookup(
          'google.com',
        ).timeout(const Duration(seconds: 3));

        if (result.isEmpty || result[0].rawAddress.isEmpty) {
          throw const SocketException('Sin conexión');
        }
      } on TimeoutException catch (_) {
        throw Exception(
          'Sin conexión a Internet. La biometría facial requiere acceso a la nube (AWS).',
        );
      } on SocketException catch (_) {
        throw Exception(
          'Sin conexión a Internet. La biometría facial requiere acceso a la nube (AWS).',
        );
      }

      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 85,
        maxWidth: 1920,
      );

      if (photo == null) throw Exception('Captura cancelada.');

      await Future.delayed(const Duration(milliseconds: 600));
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      final String base64Image = await compute(
        _processImageToBase64,
        photo.path,
      );

      // LLAMADA A AWS (También le ponemos timeout de 15 segs por si la red es muy lenta)
      final Uri verifyUrl = Uri.parse('$apiGatewayUrl/verify');
      final response = await http
          .post(
            verifyUrl,
            headers: {'Content-Type': 'application/json', 'x-api-key': apiKey},
            body: jsonEncode({'imageBase64': base64Image}),
          )
          .timeout(const Duration(seconds: 15));

      print(
        "RESPUESTA DE AWS (Verificación): ${response.statusCode} - ${response.body}",
      );

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Error del servidor');
      }

      final data = jsonDecode(response.body);
      if (data['match'] == false || data['faceId'] == null) {
        throw Exception('ROSTRO NO RECONOCIDO.');
      }

      final String faceId = data['faceId'];
      final double similarity = data['similarity'];

      // BÚSQUEDA EN FIRESTORE
      final residentQuery = await _db
          .collection('Residentes')
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
        final familyQuery = await _db
            .collectionGroup('GrupoFamiliar')
            .where('rekognitionFaceId', isEqualTo: faceId)
            .limit(1)
            .get();

        if (familyQuery.docs.isNotEmpty) {
          docEncontrado = familyQuery.docs.first;
          tipoMiembro = "Grupo Familiar";
          residentRef = docEncontrado.reference.parent.parent;
        }
      }

      if (docEncontrado == null || residentRef == null) {
        throw Exception('Rostro no asociado a residente.');
      }

      final personData = docEncontrado.data() as Map<String, dynamic>;
      final String personName =
          '${personData['nombre']} ${personData['apellido']}';

      final residentDoc = await residentRef.get();
      if (!residentDoc.exists)
        throw Exception('Residente principal no encontrado');

      final residentData = residentDoc.data() as Map<String, dynamic>;
      final String unit = residentData['torre'] != null
          ? 'Torre ${residentData['torre']} - ${residentData['numero']}'
          : 'Nº ${residentData['numero']}';

      await _logEvent(
        description:
            'Ingreso facial: $personName ($tipoMiembro)\nUnidad: $unit (Sim: ${similarity.toStringAsFixed(1)}%)',
        status: 'autorizada_facial',
        residentUid: residentData['uid'],
        residentName: '${residentData['nombre']} ${residentData['apellido']}',
        residentTower: residentData['torre'],
        residentUnit: residentData['numero'],
      );

      return {
        'success': true,
        'message': 'ACCESO AUTORIZADO:\n$personName ($tipoMiembro)\n$unit',
      };
    } catch (e) {
      // Limpiamos el mensaje de error para que se vea estético
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }

      // 2. EVITAMOS EL CONGELAMIENTO EN FIREBASE:
      // Si el error es de conexión o se canceló, NO lo guardamos en la bitácora.
      if (!errorMessage.contains('Sin conexión') &&
          !errorMessage.contains('Captura cancelada')) {
        await _logEvent(
          description: 'Ingreso facial rechazado: $errorMessage',
          status: 'rechazada_facial',
        );
      }

      return {'success': false, 'message': errorMessage};
    }
  }

  // ==========================================
  // VERIFICACIÓN LPR PATENTE (OFFLINE-FIRST INSTANTÁNEO)
  // ==========================================
  Future<Map<String, dynamic>> verifyPlateByLPR() async {
    if (_condominioId == null) throw Exception("Error de inicialización");
    String recognizedPlate = '';
    bool isOffline = false; // Controlará si usamos el modo offline

    try {
      // 1. PING RÁPIDO: Comprobamos si hay internet real (Máximo 1.5 segundos)
      try {
        final socket = await Socket.connect(
          '8.8.8.8',
          53,
          timeout: const Duration(milliseconds: 1500),
        );
        socket.destroy();
      } catch (_) {
        isOffline = true; // No hay internet, activamos el modo offline
      }

      // 2. CAPTURA Y PROCESAMIENTO (Edge Computing - Local)
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (photo == null) throw Exception('Captura cancelada.');

      await Future.delayed(const Duration(milliseconds: 600));
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      final inputImage = InputImage.fromFilePath(photo.path);
      final textRecognizer = TextRecognizer();
      final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage,
      );

      String bestMatch = '';
      final regex = RegExp(r'^[A-Z]{2}[A-Z0-9]{2}[0-9]{2}$');

      for (TextBlock block in recognizedText.blocks) {
        String text = block.text.toUpperCase().replaceAll(
          RegExp(r'[^A-Z0-9]'),
          '',
        );
        if (regex.hasMatch(text)) {
          bestMatch = text;
          break;
        } else if (text.length == 6) {
          bestMatch = text;
        }
      }
      textRecognizer.close();

      if (bestMatch.isEmpty)
        throw Exception('No se pudo leer una patente válida.');
      recognizedPlate = bestMatch;

      DocumentSnapshot? vehicleDoc;

      // 3. BÚSQUEDA INTELIGENTE
      if (isOffline) {
        // 🔥 MODO OFFLINE: Buscamos obligatoriamente en caché
        final cacheQuery = await _db
            .collectionGroup('Vehiculos')
            .where('condominioId', isEqualTo: _condominioId)
            .where('plate', isEqualTo: recognizedPlate)
            .limit(1)
            .get(const GetOptions(source: Source.cache));
        if (cacheQuery.docs.isNotEmpty) vehicleDoc = cacheQuery.docs.first;
      } else {
        // 🌐 MODO ONLINE: Buscamos en el servidor. Si falla (red inestable), caemos al caché.
        try {
          final serverQuery = await _db
              .collectionGroup('Vehiculos')
              .where('condominioId', isEqualTo: _condominioId)
              .where('plate', isEqualTo: recognizedPlate)
              .limit(1)
              .get(const GetOptions(source: Source.serverAndCache))
              .timeout(const Duration(seconds: 3));
          if (serverQuery.docs.isNotEmpty) vehicleDoc = serverQuery.docs.first;
        } catch (_) {
          isOffline = true; // Falló el servidor, cambiamos a offline
          final fallbackQuery = await _db
              .collectionGroup('Vehiculos')
              .where('condominioId', isEqualTo: _condominioId)
              .where('plate', isEqualTo: recognizedPlate)
              .limit(1)
              .get(const GetOptions(source: Source.cache));
          if (fallbackQuery.docs.isNotEmpty)
            vehicleDoc = fallbackQuery.docs.first;
        }
      }

      if (vehicleDoc == null) {
        throw Exception(
          isOffline
              ? 'PATENTE NO ENCONTRADA EN CACHÉ. (Requiere red)'
              : 'PATENTE NO REGISTRADA: $recognizedPlate',
        );
      }

      final residentRef = vehicleDoc.reference.parent.parent;
      if (residentRef == null) throw Exception('Vehículo sin residente.');

      DocumentSnapshot? residentDoc;
      try {
        residentDoc = await residentRef.get(
          GetOptions(source: isOffline ? Source.cache : Source.serverAndCache),
        );
      } catch (_) {
        residentDoc = await residentRef.get(
          const GetOptions(source: Source.cache),
        );
      }

      if (!residentDoc.exists) throw Exception('Residente no encontrado.');

      final residentData = residentDoc.data() as Map<String, dynamic>;
      final String residentName =
          '${residentData['nombre']} ${residentData['apellido']}';
      final String unit = residentData['torre'] != null
          ? 'Torre ${residentData['torre']} - ${residentData['numero']}'
          : 'Nº ${residentData['numero']}';

      // 4. REGISTRO EN BITÁCORA
      _logEvent(
        description:
            'Ingreso LPR: $residentName (Patente: $recognizedPlate) ${isOffline ? "[OFFLINE]" : ""}'
                .trim(),
        status: 'autorizada_lpr',
        residentUid: residentData['uid'],
        residentName: residentName,
        residentTower: residentData['torre'],
        residentUnit: residentData['numero'],
      );

      return {
        'success': true,
        'message':
            'ACCESO AUTORIZADO ${isOffline ? "(Offline)" : ""}:\n$residentName\n$unit (Patente: $recognizedPlate)',
      };
    } catch (e) {
      String errorMessage = e.toString().contains('Exception:')
          ? e.toString().split('Exception: ')[1].trim()
          : e.toString();
      if (!errorMessage.contains('Captura cancelada')) {
        _logEvent(
          description: 'Rechazo LPR: $errorMessage ($recognizedPlate)',
          status: 'rechazada_lpr',
        );
      }
      return {'success': false, 'message': errorMessage};
    }
  }

  // ==========================================
  // VERIFICACIÓN QR (OFFLINE-FIRST INSTANTÁNEO)
  // ==========================================
  Future<String> verifyPass(String code) async {
    if (_condominioId == null) throw Exception("Error de inicialización");
    bool isOffline = false;

    try {
      // 1. PING RÁPIDO
      try {
        final socket = await Socket.connect(
          '8.8.8.8',
          53,
          timeout: const Duration(milliseconds: 1500),
        );
        socket.destroy();
      } catch (_) {
        isOffline = true;
      }

      DocumentSnapshot? visitDoc;
      Map<String, dynamic>? visitData;

      // 2. BÚSQUEDA INTELIGENTE
      if (isOffline) {
        // 🔥 MODO OFFLINE
        final cacheQuery = await _db
            .collection('Visitas')
            .where('condominioId', isEqualTo: _condominioId)
            .where('code', isEqualTo: code)
            .limit(1)
            .get(const GetOptions(source: Source.cache));
        if (cacheQuery.docs.isNotEmpty) {
          visitDoc = cacheQuery.docs.first;
          visitData = visitDoc.data() as Map<String, dynamic>;
        }
      } else {
        // 🌐 MODO ONLINE (Si el internet se cae a la mitad, usa el caché como rescate)
        try {
          final serverQuery = await _db
              .collection('Visitas')
              .where('condominioId', isEqualTo: _condominioId)
              .where('code', isEqualTo: code)
              .limit(1)
              .get(const GetOptions(source: Source.serverAndCache))
              .timeout(const Duration(seconds: 3));
          if (serverQuery.docs.isNotEmpty) {
            visitDoc = serverQuery.docs.first;
            visitData = serverQuery.docs.first.data() as Map<String, dynamic>;
          }
        } catch (_) {
          isOffline = true;
          final fallbackQuery = await _db
              .collection('Visitas')
              .where('condominioId', isEqualTo: _condominioId)
              .where('code', isEqualTo: code)
              .limit(1)
              .get(const GetOptions(source: Source.cache));
          if (fallbackQuery.docs.isNotEmpty) {
            visitDoc = fallbackQuery.docs.first;
            visitData = fallbackQuery.docs.first.data() as Map<String, dynamic>;
          }
        }
      }

      if (visitDoc == null || visitData == null) {
        throw Exception(
          isOffline
              ? 'Pase no encontrado en caché local.'
              : 'Pase no encontrado o inválido.',
        );
      }

      // 3. VALIDACIONES LOCALES
      final String status = visitData['status'] ?? '';
      if (status != 'programada') {
        throw Exception('El pase ya fue utilizado o cancelado.');
      }

      final Timestamp? scheduledAt = visitData['scheduledAt'];
      if (scheduledAt != null &&
          scheduledAt.toDate().isBefore(DateTime.now())) {
        throw Exception('El pase ha expirado.');
      }

      // 4. ACTUALIZACIÓN LOCAL (Sincroniza en la nube luego)
      visitDoc.reference.update({
        'status': 'autorizada',
        'checkedByGuardUid': uid,
        'checkedAt': FieldValue.serverTimestamp(),
      });

      final String residentUid = visitData['residentUid'] ?? '';
      String residentName = 'Desconocido';
      String? residentTower;
      String? residentUnit;

      final residentLocal = residentsList.firstWhere(
        (r) => r['uid'] == residentUid,
        orElse: () => {},
      );
      if (residentLocal.isNotEmpty) {
        residentName = residentLocal['nombre'];
        residentTower = residentLocal['torre']?.toString();
        residentUnit = residentLocal['numero']?.toString();
      }

      final vName = visitData['visitorName'] ?? '';
      final vLastName = visitData['visitorLastName'] ?? '';
      final vId = visitData['visitorId'] ?? '';

      final description =
          'Ingreso QR: $vName $vLastName $vId ${isOffline ? "[OFFLINE]" : ""}'
              .trim();

      _logEvent(
        description: description,
        status: 'autorizada_qr',
        residentUid: residentUid,
        residentName: residentName,
        residentTower: residentTower,
        residentUnit: residentUnit,
      );

      return 'PASE AUTORIZADO ${isOffline ? "(Offline)" : ""}:\n$vName $vLastName';
    } catch (e) {
      String errorMessage = e.toString().contains('Exception:')
          ? e.toString().split('Exception: ')[1].trim()
          : e.toString();
      _logEvent(
        description: 'QR rechazado: $code ($errorMessage)',
        status: 'rechazada_qr',
      );
      throw Exception(errorMessage);
    }
  }

  Future<Map<String, dynamic>> notifyOrLogManual({
    required String residentUid,
    required String residentName,
    String? visitorName,
    String? torre,
    String? numero,
  }) async {
    if (_condominioId == null)
      return {'status': 'error', 'message': 'Error de inicialización'};

    try {
      if (visitorName != null && visitorName.isNotEmpty) {
        final newNotification = await _db
            .collection('notificaciones_visita')
            .add({
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

        return {
          'status': 'notificando',
          'docId': newNotification.id,
          'message': 'Notificando a $residentName...',
        };
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

  Future<void> logApprovedVisit({
    required String visitorName,
    required String residentName,
    required String residentUid,
    String? torre,
    String? numero,
  }) async {
    await _logEvent(
      description: 'Ingreso de $visitorName aprobado por $residentName.',
      status: 'autorizada_notificacion',
      residentUid: residentUid,
      residentName: residentName,
      residentTower: torre,
      residentUnit: numero,
    );
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
