import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

// MODELOS COMPARTIDOS
enum VisitStatus { programada, autorizada, rechazada, expirada }

class VisitPass {
  VisitPass({
    required this.id,
    required this.code,
    required this.visitorName,
    this.visitorLastName,
    this.visitorId,
    this.phone,
    this.plate,
    required this.scheduledAt,
    required this.hostResident,
    this.status = VisitStatus.programada,
  });
  final String id;
  final String code;
  final String visitorName;
  final String? visitorLastName; // AÑADIDO
  final String? visitorId;
  final String? phone;
  final String? plate;
  final DateTime scheduledAt;
  final String hostResident;
  VisitStatus status;

  factory VisitPass.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VisitPass(
      id: doc.id,
      code: data['code'] ?? '',
      visitorName: data['visitorName'] ?? '',
      visitorLastName: data['visitorLastName'],
      visitorId: data['visitorId'],
      phone: data['phone'],
      plate: data['plate'],
      scheduledAt: (data['scheduledAt'] as Timestamp).toDate(),
      hostResident: '', // Este dato suele venir de otro lado, se puede dejar vacío o llenar luego
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

class Vehicle {
  final String id; // <-- AÑADIR
  final String plate;
  final String? alias;

  Vehicle({
    required this.id, // <-- AÑADIR
    required this.plate, 
    this.alias
  });

  factory Vehicle.fromFirestore(DocumentSnapshot doc) { // <-- AÑADIR
    final data = doc.data() as Map<String, dynamic>;
    return Vehicle(
      id: doc.id,
      plate: data['plate'] ?? '',
      alias: data['alias'],
    );
  }
}

class FamilyMember {
  final String id;
  final String nombre;
  final String apellido;
  final String? rut;
  final bool hasFaceId;

  FamilyMember({
    required this.id,
    required this.nombre,
    required this.apellido,
    this.rut,
    this.hasFaceId = false,
  });

  factory FamilyMember.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FamilyMember(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      apellido: data['apellido'] ?? '',
      rut: data['rut'],
      hasFaceId: data['hasFaceId'] ?? false,
    );
  }
}

// Modelo para el Administrador
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

// Modelo para el Guardia
class AccessEvent {
  final String id;
  final String description;
  final String status;
  final DateTime timestamp;
  final String? residentName;

  AccessEvent({
    required this.id,
    required this.description,
    required this.status,
    required this.timestamp,
    this.residentName,
  });

  // --- ESTA ES LA FUNCIÓN QUE TE FALTABA ---
  factory AccessEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AccessEvent(
      id: doc.id,
      description: data['description'] ?? 'Evento sin descripción',
      status: data['status'] ?? 'desconocido',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      residentName: data['residentName'],
    );
  }
}


// --- FUNCIONES DE MOCKING (Creación de IDs/Códigos) ---
// (También movidas de resident_state.dart para ser reutilizables)
String mkId() => Random().nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();
String mkCode() => 'PASS-${Random().nextInt(0xFFFF).toRadixString(16).padLeft(4, '0').toUpperCase()}';

class CondoType {
  final String id;
  final String name;

  CondoType({required this.id, required this.name});

  // Factory para crear una instancia desde un documento de Firestore
  factory CondoType.fromFirestore(Map<String, dynamic> data, String documentId) {
    return CondoType(
      id: documentId,
      name: data['name'] ?? 'Nombre no encontrado',
    );
  }
}
