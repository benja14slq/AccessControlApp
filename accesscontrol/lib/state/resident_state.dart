import 'dart:math';
import 'package:flutter/material.dart';

enum VisitStatus { programada, autorizada, rechazada, expirada }

class VisitPass {
  VisitPass({
    required this.id,
    required this.code,
    required this.visitorName,
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

class ResidentState extends ChangeNotifier {
  ResidentState() {
    visits.addAll([
      VisitPass(
        id: _mkId(),
        code: _mkCode(),
        visitorName: 'Carolina Pérez',
        visitorId: '21.234.567-8',
        phone: '+56 9 8123 4567',
        plate: 'KJLT-23',
        scheduledAt: DateTime.now().add(const Duration(hours: 1)),
        hostResident: residentEmail,
      ),
      VisitPass(
        id: _mkId(),
        code: _mkCode(),
        visitorName: 'Jorge Silva',
        visitorId: '18.345.678-9',
        phone: '+56 9 7777 0000',
        scheduledAt: DateTime.now().add(const Duration(hours: 3)),
        hostResident: residentEmail,
      ),
    ]);
    vehicles.add(Vehicle(plate: 'JKPX-88', alias: 'Auto azul'));
  }

  final String residentEmail = 'residente@condo.cl';
  bool hasFaceId = false;
  final List<VisitPass> visits = [];
  final List<Vehicle> vehicles = [];
  bool notifEmail = true;
  bool notifPush = true;

  void toggleFaceId() { hasFaceId = !hasFaceId; notifyListeners(); }

  void addVehicle(String plate, String? alias) {
    vehicles.insert(0, Vehicle(plate: plate, alias: alias));
    notifyListeners();
  }

  void removeVehicleAt(int index) { vehicles.removeAt(index); notifyListeners(); }

  void createVisit({
    required String visitorName,
    String? visitorId,
    String? phone,
    String? plate,
    required DateTime scheduledAt,
  }) {
    final pass = VisitPass(
      id: _mkId(),
      code: _mkCode(),
      visitorName: visitorName,
      visitorId: visitorId,
      phone: phone,
      plate: plate?.toUpperCase(),
      scheduledAt: scheduledAt,
      hostResident: residentEmail,
    );
    visits.insert(0, pass);
    notifyListeners();
  }

  void setNotifEmail(bool v) { notifEmail = v; notifyListeners(); }
  void setNotifPush(bool v) { notifPush = v; notifyListeners(); }
}

String _mkId() => Random().nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();
String _mkCode() => 'PASS-${Random().nextInt(0xFFFF).toRadixString(16).padLeft(4, '0').toUpperCase()}';