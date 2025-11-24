import 'dart:async';
import 'package:accesscontrol/shared/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:accesscontrol/shared/api_constants.dart';
import 'dart:math';

String mkCode() => 'PASS-${Random().nextInt(0xFFFF).toRadixString(16).padLeft(4, '0').toUpperCase()}';

class ResidentState extends ChangeNotifier {
  final String uid;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late final DocumentReference _residentDocRef;

  late String _adminUid;

  final List<StreamSubscription> _subscriptions = [];
  List<FamilyMember> familyMembers = [];
  List<DocumentSnapshot> pendingNotifications = [];

  // --- DATOS DEL ESTADO ---
  String residentEmail = '';
  String residentName = '';
  String residentLastName = '';
  String condoName = '';
  String condoUnit = '';
  bool hasFaceId = false;
  bool notifEmail = true;
  bool notifApp = true;
  List<Vehicle> vehicles = [];

  List<VisitPass> _upcomingVisitsList = [];
  bool isLoading = true;

  Map<String, dynamic> condoConfig = {};

  ResidentState({required this.uid}) {
    init();
  }

  Future<void> init() async {
    isLoading = true;
    notifyListeners();
    try{
      final query = await _db.collection('Residentes')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();

      if (query.docs.isEmpty){
        throw Exception("Error Crítico: No se encontró el documento del residente para el UID: $uid");
      }

      _residentDocRef = query.docs.first.reference;

      await _loadAllData();
      await _initFCM();
  
    } catch (e) {
      print("Error en init: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadAllData() async {
    try {
      await _loadProfile();
      await Future.wait([
        _loadVehicles(),
        _loadVisits(),
        _loadFamilyMembers(),
        _loadPendingNotifications(),
        _loadConfig(),
      ]);
    } catch (e) {
      print("Error durante la carga inicial de datos: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadProfile() async {
    final completer = Completer<void>();
    final sub = _residentDocRef.snapshots().listen(
      (doc) {
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          _adminUid = data['adminUid'];
          residentEmail = data['correo'] ?? '';
          residentName = data['nombre'] ?? '';
          residentLastName = data['apellido'] ?? '';
          condoName = data['nombreCondominio'] ?? '';
          hasFaceId = data['hasFaceId'] ?? false;
          notifEmail = data['notifEmail'] ?? true;
          notifApp = data['notifApp'] ?? true;
          final torre = data['torre'] != null ? 'Torre ${data['torre']}' : '';
          final numero = data['numero'] ?? '';
          condoUnit = '$torre $numero'.trim();
          notifyListeners();
          if (!completer.isCompleted) completer.complete();
        }
      },
      onError: (error) {
        if (!completer.isCompleted) completer.completeError(error);
        print("Error en stream _loadProfile: $error");
      }
    );
    _subscriptions.add(sub);
    return completer.future;
  }

  Future<void> _loadConfig() {
    final completer = Completer<void>();
    final sub = _db.collection('Administradores').doc(_adminUid).snapshots().listen(
      (adminDoc) {
        if (!completer.isCompleted) completer.complete();
        if (adminDoc.exists) {
          condoConfig = adminDoc.data()?['configuracion'] ?? {};
          notifyListeners();
        }
      },
      onError: (error) {
        if (!completer.isCompleted) completer.completeError(error);
        print("Error en stream de Configuración: $error");
      }
    );
    _subscriptions.add(sub);
    return completer.future;
  }

  Future<void> _loadVehicles() {
    final completer = Completer<void>();
    final sub = _residentDocRef.collection('Vehiculos').snapshots().listen(
      (snapshot) {
        if (!completer.isCompleted) completer.complete();
        vehicles = snapshot.docs.map((doc) => Vehicle.fromFirestore(doc)).toList();
        notifyListeners();
      },
      onError: (error) {
         if (!completer.isCompleted) completer.completeError(error);
         print("Error en stream _loadVehicles: $error");
      }
    );
    _subscriptions.add(sub);
    return completer.future;
  }

  Future<void> _loadVisits() {
    final completer = Completer<void>();
    final sub = _db.collection('Visitas')
        .where('residentUid', isEqualTo: uid)
        .where('status', isEqualTo: 'programada') 
        .where('scheduledAt', isGreaterThan: Timestamp.now())
        .orderBy('scheduledAt', descending: false)
        .snapshots()
        .listen(
      (snapshot) {
        if (!completer.isCompleted) completer.complete();
        _upcomingVisitsList = snapshot.docs.map((doc) {
          final data = doc.data();
          return VisitPass(
            id: doc.id,
            code: data['code'] ?? 'Error',
            visitorName: data['visitorName'] ?? '',
            visitorLastName: data['visitorLastName'] ?? '',
            visitorId: data['visitorId'],
            phone: data['phone'],
            plate: data['plate'],
            scheduledAt: (data['scheduledAt'] as Timestamp).toDate(),
            hostResident: '$residentName $residentLastName',
            status: VisitStatus.programada, 
          );
        }).toList();
        notifyListeners(); 
      },
      onError: (error) {
         if (!completer.isCompleted) completer.completeError(error);
         print("Error en stream _loadVisits: $error");
      }
    );
    _subscriptions.add(sub);
    return completer.future;
  }

  Future<void> _loadFamilyMembers(){
    final completer = Completer<void>();
    final sub = _residentDocRef.collection('GrupoFamiliar').snapshots().listen(
      (snapshot){
        if (!completer.isCompleted) completer.complete();
        familyMembers = snapshot.docs.map((doc) => FamilyMember.fromFirestore(doc)).toList();
        notifyListeners();
      },
      onError: (error) {
        if (!completer.isCompleted) completer.completeError(error);
        print("Error en stream _loadFamilyMembers: $error");
      }
    );
    _subscriptions.add(sub);
    return completer.future;
  }

  Future<void> _loadPendingNotifications() {
    final completer = Completer<void>();
    final sub = _db.collection('notificaciones_visita')
        .where('residentUid', isEqualTo: uid)
        .where('status', isEqualTo: 'pendiente')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        if (!completer.isCompleted) completer.complete();
        pendingNotifications = snapshot.docs;
        notifyListeners();
      },
      onError: (error) {
         if (!completer.isCompleted) completer.completeError(error);
         print("Error en stream _loadPendingNotifications: $error");
      }
    );
    _subscriptions.add(sub);
    return completer.future;
  }

  Future<void> respondToNotification(String notificationId, bool approve) async {
    try {
      await _db.collection('notificaciones_visita').doc(notificationId).update({
        'status': approve ? 'aprobada' : 'rechazada',
        'respondedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error al responder notificación: $e");
    }
  }

  Future<void> _initFCM() async {
    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await messaging.getToken();
    if (token != null) {
      print('FCM Token: $token');
      await _residentDocRef.update({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> addVehicle(String plate, String? alias) async {
    try {
      final cleanPlate = plate.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
      
      await _residentDocRef.collection('Vehiculos').add({
        'plate': cleanPlate,
        'alias': alias,
        'createdAt': FieldValue.serverTimestamp(),
        'adminUid': _adminUid,
      });
    } catch (e) {
      print("Error al añadir vehículo: $e");
      rethrow;
    }
  }

  Future<void> removeVehicleAt(int index) async {
    try {
      final vehicleId = vehicles[index].id; 
      await _residentDocRef.collection('Vehiculos').doc(vehicleId).delete();
    } catch (e) {
      print("Error al eliminar vehículo: $e");
      rethrow;
    }
  }

  Future<void> createVisit({
    required String visitorName,
    required String visitorLastName,
    required String? rut,
    required String? phone,
    required String? plate,
    required DateTime scheduledAt,
  }) async {
    try {
      await _db.collection('Visitas').add({
        'adminUid': _adminUid, // Usa el _adminUid que ya cargamos
        'residentUid': uid,
        'visitorName': visitorName,
        'visitorLastName': visitorLastName, // Campo nuevo
        'visitorId': rut, // Campo renombrado
        'phone': phone,
        'plate': plate,
        'code': mkCode(), // Función global que ya tienes
        'status': 'programada',
        'createdAt': FieldValue.serverTimestamp(),
        'scheduledAt': Timestamp.fromDate(scheduledAt), // Renombrado
      });
    } catch (e) {
      print("Error al crear visita: $e");
      rethrow; // Lanza el error para que la UI lo atrape
    }
  }

  Future<void> addFamilyMember({
    required String nombre,
    required String apellido,
    String? rut,
  }) async {
    try {
      await _residentDocRef.collection('GrupoFamiliar').add({
        'nombre': nombre,
        'apellido': apellido,
        'rut': rut,
        'hasFaceId': false,
        'createdAt': FieldValue.serverTimestamp(),
        'adminUid': _adminUid,
      });
    } catch (e) {
      print('Error al añadir miembro familiar: $e');
      rethrow;
    }
  }

  Future<void> registerFamilyMemberFace(String memberId) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 80,
        maxWidth: 1080,
      );

      if (photo == null) return;

      final bytes = await File(photo.path).readAsBytes();
      final String base64Image = base64Encode(bytes);

      // 1. Llama a la *misma* Lambda de registro
      final Uri registerUrl = Uri.parse('$apiGatewayUrl/register');
      final response = await http.post(
        registerUrl,
        headers: { 'Content-Type': 'application/json', 'x-api-key': apiKey },
        body: jsonEncode({ 'imageBase64': base64Image }),
      );

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'No se pudo registrar el rostro.');
      }

      final data = jsonDecode(response.body);
      final String faceId = data['faceId'];

      // 2. Guarda el FaceId en el documento del *miembro familiar*
      await _residentDocRef.collection('GrupoFamiliar').doc(memberId).update({
        'hasFaceId': true,
        'rekognitionFaceId': faceId,
      });

      // El listener _loadFamilyMembers se encargará de actualizar la UI
      
    } catch (e) {
      print('Error al registrar rostro familiar: $e');
      rethrow;
    }
  }

  Future<void> setNotifEmail(bool v) async { notifEmail = v; notifyListeners(); await _residentDocRef.update({'notifEmail': v}); }
  Future<void> setNotifApp(bool v) async { notifApp = v; notifyListeners(); await _residentDocRef.update({'notifApp': v}); }


  Future<void> registerFaceId() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 80,
        maxWidth: 1080,
      );

      if (photo == null) return; 

      final bytes = await File(photo.path).readAsBytes();
      final String base64Image = base64Encode(bytes);

      // --- USA LAS CONSTANTES AQUÍ ---
      final Uri registerUrl = Uri.parse('$apiGatewayUrl/register');
      
      final response = await http.post(
        registerUrl,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey, // <-- Usa la constante
        },
        body: jsonEncode({
          'imageBase64': base64Image,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String faceId = data['faceId']; 

        await _residentDocRef.update({
          'hasFaceId': true,
          'rekognitionFaceId': faceId, 
        });
        
      } else {
        print('Error del servidor: ${response.body}');
        throw Exception('No se pudo registrar el rostro.');
      }
    } catch (e) {
      print('Error al registrar rostro: $e');
      rethrow; 
    }
  }
  // --- GETTERS SIMPLIFICADOS ---
  List<VisitPass> get upcomingVisits {
    return _upcomingVisitsList;
  }

  int get visitsTodayCount {
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return _upcomingVisitsList.where((v) =>
        v.scheduledAt.isBefore(endOfDay)
    ).length;
  }

  @override
  void dispose() {
    for (var sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }
}