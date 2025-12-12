import 'package:accesscontrol/shared/models.dart';
import 'package:accesscontrol/shared/utils.dart';
import 'package:accesscontrol/shared/widgets/status_chip.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class VisitPassPage extends StatefulWidget {
  const VisitPassPage({super.key});

  @override
  State<VisitPassPage> createState() => _VisitPassPageState();
}

class _VisitPassPageState extends State<VisitPassPage> {
  VisitPass? _pass;
  String _hostName = ''; 
  bool _isLoading = false;
  final _codeCtrl = TextEditingController();
  
  Future<void> _findPass() async {
    setState(() {
      _isLoading = true;
      _pass = null;
      _hostName = '';
    });
    
    try {
      final code = _codeCtrl.text.trim().toUpperCase();

      final query = await FirebaseFirestore.instance
          .collection('Visitas')
          .where('code', isEqualTo: code)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        throw Exception('Código no encontrado o expirado.');
      }

      final visitDoc = query.docs.first;
      final data = visitDoc.data();
      final residentUid = data['residentUid'];

      if (residentUid != null) {
        final residentDoc = await FirebaseFirestore.instance
            .collection('Residentes')
            .where('uid', isEqualTo: residentUid)
            .limit(1)
            .get();
        
        if (residentDoc.docs.isNotEmpty) {
          final residentData = residentDoc.docs.first.data();
          _hostName = '${residentData['nombre']} ${residentData['apellido']}';
        }
      }

      setState(() {
        _pass = VisitPass(
          id: visitDoc.id,
          code: data['code'],
          visitorName: data['visitorName'],
          scheduledAt: (data['scheduledAt'] as Timestamp).toDate(),
          hostResident: _hostName,
          status: VisitStatus.values.firstWhere(
            (e) => e.toString() == 'VisitStatus.${data['status']}',
            orElse: () => VisitStatus.programada,
          ),
        );
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red)
      );
    } finally {
      setState(() => _isLoading = false);
      FocusManager.instance.primaryFocus?.unfocus();
    }
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
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search), 
                  onPressed: _isLoading ? null : _findPass,
                ),
              ),
              onSubmitted: (_) => _findPass(),
            ),
            
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
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
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: QrImageView(
                                data: _pass!.code,
                                version: QrVersions.auto,
                                size: 180.0,
                                gapless: false,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(_pass!.code, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            StatusChip(_pass!.status),
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
                              title: Text(formatCompact(_pass!.scheduledAt)),
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