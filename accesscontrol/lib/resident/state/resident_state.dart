import 'package:accesscontrol/shared/models.dart';
import 'package:flutter/material.dart';

class ResidentState extends ChangeNotifier {
  ResidentState() {
    visits.addAll([
      VisitPass(
        id: mkId(),
        code: mkCode(),
        visitorName: 'Carolina Pérez',
        visitorId: '21.234.567-8',
        phone: '+56 9 8123 4567',
        plate: 'KJLT-23',
        scheduledAt: DateTime.now().add(const Duration(hours: 1)),
        hostResident: residentEmail,
      ),
      VisitPass(
        id: mkId(),
        code: mkCode(),
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
      id: mkId(),
      code: mkCode(),
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