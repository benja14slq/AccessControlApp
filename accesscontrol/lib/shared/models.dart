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
}

class Vehicle {
  Vehicle({required this.plate, this.alias});
  final String plate;
  final String? alias;
}

// Modelo para el Administrador
class CondoUser {
  final String email;
  final String role; // "Residente" o "Guardia"
  final String unit; // Ej: "Depto 402" o "Turno Noche"
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
  final String description;
  final DateTime timestamp;
  AccessEvent({required this.description, required this.timestamp});
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

class FamilyMember {
  final String id; // Document ID
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