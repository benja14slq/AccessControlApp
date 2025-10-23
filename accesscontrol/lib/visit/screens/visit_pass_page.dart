import 'package:accesscontrol/resident/state/resident_state.dart';
import 'package:accesscontrol/shared/models.dart';
import 'package:accesscontrol/shared/widgets/status_chip.dart';
import 'package:accesscontrol/shared/utils.dart';
import 'package:flutter/material.dart';

class VisitPassPage extends StatefulWidget {
  const VisitPassPage({super.key, required this.residentState});
  final ResidentState residentState;

  @override
  State<VisitPassPage> createState() => _VisitPassPageState();
}

class _VisitPassPageState extends State<VisitPassPage> {
  
  VisitPass? _pass;
  final _codeCtrl = TextEditingController();

  void _findPass() {
    setState(() => _pass = null);
    try {
      final code = _codeCtrl.text.trim().toUpperCase();
      final foundPass = widget.residentState.visits.firstWhere((v) => v.code == code);
      setState(() => _pass = foundPass);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Código no encontrado')));
    }
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Pase de Visita')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _codeCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Ingresa tu código de acceso',
                suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: _findPass),
              ),
              onSubmitted: (_) => _findPass(),
            ),
            
            if (_pass != null)
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('PASE DE VISITA', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 16),
                            // Simulación de QR Code
                            Icon(Icons.qr_code_2, size: 150, color: Colors.blueGrey.shade800),
                            const SizedBox(height: 16),
                            Text(_pass!.code, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            StatusChip(_pass!.status), // Reutilizamos tu widget
                            const SizedBox(height: 16),
                            ListTile(
                              title: Text(_pass!.visitorName), 
                              subtitle: const Text('Visitante'),
                            ),
                            ListTile(
                              title: Text(_pass!.hostResident), 
                              subtitle: const Text('Anfitrión (Residente)'),
                            ),
                            ListTile(
                              title: Text(formatCompact(_pass!.scheduledAt)), // Reutilizamos tu util
                              subtitle: const Text('Fecha programada'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}