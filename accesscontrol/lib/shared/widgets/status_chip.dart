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
        color: _statusBg(status, context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _text(status),
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _statusFg(status)),
      ),
    );
  }

  String _text(VisitStatus s) {
    switch (s) {
      case VisitStatus.programada: return 'programada';
      case VisitStatus.autorizada: return 'autorizada';
      case VisitStatus.rechazada:  return 'rechazada';
      case VisitStatus.expirada:   return 'expirada';
    }
  }

  Color _statusBg(VisitStatus s, BuildContext ctx) {
    switch (s) {
      case VisitStatus.programada: return Theme.of(ctx).colorScheme.secondaryContainer;
      case VisitStatus.autorizada: return Colors.green.shade100;
      case VisitStatus.rechazada:  return Colors.red.shade100;
      case VisitStatus.expirada:   return Colors.grey.shade200;
    }
  }

  Color _statusFg(VisitStatus s) {
    switch (s) {
      case VisitStatus.programada: return Colors.orange.shade800;
      case VisitStatus.autorizada: return Colors.green.shade800;
      case VisitStatus.rechazada:  return Colors.red.shade800;
      case VisitStatus.expirada:   return Colors.grey.shade800;
    }
  }
}