import 'package:accesscontrol/shared/models.dart'; // Importación actualizada
import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});
  final VisitStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: _statusBg(status),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _statusFg(status).withOpacity(0.5)),
      ),
      child: Text(
        _text(status),
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _statusFg(status)),
      ),
    );
  }

  String _text(VisitStatus s) {
    switch (s) {
      case VisitStatus.programada: return 'PROGRAMADA';
      case VisitStatus.autorizada: return 'INGRESÓ';
      case VisitStatus.rechazada:  return 'RECHAZADA';
      case VisitStatus.expirada:   return 'EXPIRADA';
    }
  }

  Color _statusBg(VisitStatus s) {
    switch (s) {
      case VisitStatus.programada: return Colors.blue.shade50;
      case VisitStatus.autorizada: return Colors.green.shade50;
      case VisitStatus.rechazada:  return Colors.red.shade50;
      case VisitStatus.expirada:   return Colors.grey.shade200;
    }
  }

  Color _statusFg(VisitStatus s) {
    switch (s) {
      case VisitStatus.programada: return Colors.blue.shade700;
      case VisitStatus.autorizada: return Colors.green.shade700;
      case VisitStatus.rechazada:  return Colors.red.shade700;
      case VisitStatus.expirada:   return Colors.grey.shade600;
    }
  }
}