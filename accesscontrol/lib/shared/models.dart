import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

enum VisitStatus { programada, autorizada, rechazada, expirada }

// --------------------------------------------------------
// 1. ENTIDADES PRINCIPALES (Nuevos Modelos)
// --------------------------------------------------------

class Condominio {
  final String id; // uid de la colección
  final String nombreCondominio;
  final String? tipoCondominioID;
  final Map<String, dynamic> configuracion;

  Condominio({
    required this.id,
    required this.nombreCondominio,
    this.tipoCondominioID,
    required this.configuracion,
  });

  factory Condominio.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Condominio(
      id: doc.id,
      nombreCondominio: data['nombreCondominio'] ?? '',
      tipoCondominioID: data['tipoCondominioID'],
      configuracion: data['configuracion'] ?? {},
    );
  }
}

class Administrador {
  final String id; // uid
  final String? rut;
  final String nombre;
  final String? apellido;
  final String email;
  final List<String> condominiosIds; // Multi-tenant

  Administrador({
    required this.id,
    this.rut,
    required this.nombre,
    this.apellido,
    required this.email,
    required this.condominiosIds,
  });

  factory Administrador.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Administrador(
      id: doc.id,
      rut: data['rut'],
      nombre: data['nombre'] ?? '',
      apellido: data['apellido'],
      email: data['email'] ?? '',
      condominiosIds: List<String>.from(data['condominiosIds'] ?? []),
    );
  }
}

class Guardia {
  final String id; // uid
  final String condominioId; // FK al condominio (¡Cambio clave!)
  final String nombre;
  final String? apellido;
  final String correo;
  final String estado;

  Guardia({
    required this.id,
    required this.condominioId,
    required this.nombre,
    this.apellido,
    required this.correo,
    required this.estado,
  });

  factory Guardia.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Guardia(
      id: doc.id,
      condominioId: data['condominioId'] ?? '',
      nombre: data['nombre'] ?? '',
      apellido: data['apellido'],
      correo: data['correo'] ?? '',
      estado: data['estado'] ?? 'Pendiente',
    );
  }
}

class Residente {
  final String id; // uid
  final String condominioId; // FK al condominio (¡Cambio clave!)
  final String? rut;
  final String nombre;
  final String? apellido;
  final String correo;
  final String? torre;
  final String? numero;
  final String? fcmToken;
  final bool hasFaceId;
  final String? rekognitionFaceId;

  Residente({
    required this.id,
    required this.condominioId,
    this.rut,
    required this.nombre,
    this.apellido,
    required this.correo,
    this.torre,
    this.numero,
    this.fcmToken,
    this.hasFaceId = false,
    this.rekognitionFaceId,
  });

  factory Residente.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Residente(
      id: doc.id,
      condominioId: data['condominioId'] ?? '',
      rut: data['rut'],
      nombre: data['nombre'] ?? '',
      apellido: data['apellido'],
      correo: data['correo'] ?? '',
      torre: data['torre'],
      numero: data['numero'],
      fcmToken: data['fcmToken'],
      hasFaceId: data['hasFaceId'] ?? false,
      rekognitionFaceId: data['rekognitionFaceId'],
    );
  }
}

// --------------------------------------------------------
// 2. SUB-COLECCIONES Y RECURSOS
// --------------------------------------------------------

class FamilyMember {
  final String id;
  final String nombre;
  final String apellido;
  final String? rut;
  final bool hasFaceId;
  final String? rekognitionFaceId; // Agregado según documento

  FamilyMember({
    required this.id,
    required this.nombre,
    required this.apellido,
    this.rut,
    this.hasFaceId = false,
    this.rekognitionFaceId,
  });

  factory FamilyMember.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FamilyMember(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      apellido: data['apellido'] ?? '',
      rut: data['rut'],
      hasFaceId: data['hasFaceId'] ?? false,
      rekognitionFaceId: data['rekognitionFaceId'],
    );
  }
}

class Vehicle {
  final String id; 
  final String plate;
  final String? alias;
  // Es buena práctica guardar el condominioId en el vehículo 
  // para poder hacer "Collection Group Queries" rápido con el LPR
  final String? condominioId; 

  Vehicle({
    required this.id,
    required this.plate, 
    this.alias,
    this.condominioId,
  });

  factory Vehicle.fromFirestore(DocumentSnapshot doc) { 
    final data = doc.data() as Map<String, dynamic>;
    return Vehicle(
      id: doc.id,
      plate: data['plate'] ?? '',
      alias: data['alias'],
      condominioId: data['condominioId'],
    );
  }
}

// --------------------------------------------------------
// 3. TRANSACCIONALES (Visitas y Eventos)
// --------------------------------------------------------

class VisitPass {
  VisitPass({
    required this.id,
    required this.code,
    required this.condominioId,      // Agregado
    required this.residentUid,       // Renombrado para mayor claridad
    this.checkedByGuardUid,          // Agregado
    required this.visitorName,
    this.visitorLastName,
    this.visitorId,
    this.phone,
    this.plate,
    required this.scheduledAt,
    this.status = VisitStatus.programada,
  });

  final String id;
  final String code;
  final String condominioId; 
  final String residentUid;
  final String? checkedByGuardUid;
  final String visitorName;
  final String? visitorLastName; 
  final String? visitorId;
  final String? phone;
  final String? plate;
  final DateTime scheduledAt;
  VisitStatus status;

  factory VisitPass.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VisitPass(
      id: doc.id,
      code: data['code'] ?? '',
      condominioId: data['condominioId'] ?? '',
      residentUid: data['residentUid'] ?? '',
      checkedByGuardUid: data['checkedByGuardUid'],
      visitorName: data['visitorName'] ?? '',
      visitorLastName: data['visitorLastName'],
      visitorId: data['visitorId'],
      phone: data['phone'],
      plate: data['plate'],
      scheduledAt: (data['scheduledAt'] as Timestamp).toDate(),
      status: _mapStatus(data['status']),
    );
  }

  static VisitStatus _mapStatus(String? status) {
    switch (status) {
      case 'autorizada': return VisitStatus.autorizada;
      case 'rechazada': return VisitStatus.rechazada;
      case 'expirada': return VisitStatus.expirada;
      default: return VisitStatus.programada;
    }
  }
}

class AccessEvent {
  final String id;
  final String condominioId; // Agregado (Fundamental para reportes)
  final String? guardUid;    // Agregado
  final String? residentUid; // Agregado
  final String description;
  final String status;
  final DateTime timestamp;
  final String? residentName;

  AccessEvent({
    required this.id,
    required this.condominioId,
    this.guardUid,
    this.residentUid,
    required this.description,
    required this.status,
    required this.timestamp,
    this.residentName,
  });

  factory AccessEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AccessEvent(
      id: doc.id,
      condominioId: data['condominioId'] ?? '',
      guardUid: data['guardUid'],
      residentUid: data['residentUid'],
      description: data['description'] ?? 'Evento sin descripción',
      status: data['status'] ?? 'desconocido',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      residentName: data['residentName'],
    );
  }
}

// --------------------------------------------------------
// 4. OTROS Y UTILIDADES
// --------------------------------------------------------

class CondoType {
  final String id;
  final String name;

  CondoType({required this.id, required this.name});

  factory CondoType.fromFirestore(Map<String, dynamic> data, String documentId) {
    return CondoType(
      id: documentId,
      name: data['name'] ?? 'Nombre no encontrado',
    );
  }
}

class CondoUser {
  final String email;
  final String role; 
  final String unit; 
  bool registered;
  
  CondoUser({
    required this.email,
    required this.role,
    this.unit = '',
    this.registered = false,
  });
}

String mkId() => Random().nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();
String mkCode() => 'PASS-${Random().nextInt(0xFFFF).toRadixString(16).padLeft(4, '0').toUpperCase()}';