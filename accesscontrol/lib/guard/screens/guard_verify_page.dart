import 'package:accesscontrol/guard/screens/guard_scanner_page.dart';
import 'package:accesscontrol/guard/state/guard_state.dart';
import 'package:flutter/material.dart';
import 'package:accesscontrol/guard/screens/smart_camera_page.dart';

class GuardVerifyPage extends StatefulWidget {
  const GuardVerifyPage({super.key, required this.state});
  final GuardState state;

  @override
  State<GuardVerifyPage> createState() => _GuardVerifyPageState();
}

class _GuardVerifyPageState extends State<GuardVerifyPage> {
  final _codeCtrl = TextEditingController();
  String _result = '';
  bool _isSuccess = false;
  bool _isLoading = false;

  Future<void> _verify([String? codeFromScanner]) async {
    final code = codeFromScanner ?? _codeCtrl.text.trim();
    if (code.isEmpty) return;
    
    // 1. Mostrar Spinner inmediatamente
    setState(() {
      _isLoading = true;
      _result = '';
      _codeCtrl.text = code;
    });

    // 2. Darle tiempo al UI para que dibuje el spinner y a la cámara para apagarse
    await Future.delayed(const Duration(milliseconds: 600));
    
    if (!mounted) return;

    try {
      final result = await widget.state.verifyPass(code);

      if (mounted) {
        setState(() {
          _result = result;
          _isSuccess = result.startsWith('PASE AUTORIZADO');
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _result = e.toString().replaceAll("Exception: ", "");
          _isSuccess = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openScanner() async {
    final scannedCode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const GuardScannerPage()),
    );

    if (scannedCode != null && scannedCode.isNotEmpty) {
      _verify(scannedCode);
    }
  }

  // Recuerda importar el archivo de la cámara inteligente arriba:
// import 'package:accesscontrol/guard/screens/smart_camera_page.dart';

  Future<void> _verifyFace() async {
    if (_isLoading) return;

    // 1. Abrimos la cámara inteligente
    final imagePath = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const SmartCameraPage(
        isFrontCamera: true, 
        title: 'Verificación Facial'
      )),
    );

    // 2. Volvimos de la cámara con una foto
    if (imagePath != null) {
      // Dibujamos el spinner de carga inmediatamente
      setState(() {
        _isLoading = true;
        _result = '';
        _codeCtrl.clear();
      });

      // 3. LA MAGIA ANTI-CONGELAMIENTO:
      // Esperamos 800ms. 
      // - 300ms son para que Flutter termine la animación de cerrar la pantalla.
      // - 500ms son para que el teléfono limpie la memoria RAM de la cámara.
      await Future.delayed(const Duration(milliseconds: 800));

      try {
        // 4. Ahora que la interfaz está tranquila, hacemos el trabajo pesado
        final result = await widget.state.verifyFaceByImage(imagePath);
        
        if (mounted) {
          setState(() {
            _result = result['message'];
            _isSuccess = result['success'];
          });
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _verifyPlate() async {
    if (_isLoading) return;

    final imagePath = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const SmartCameraPage(
        isFrontCamera: false, 
        title: 'Escanear Patente'
      )),
    );

    if (imagePath != null) {
      setState(() {
        _isLoading = true;
        _result = '';
        _codeCtrl.clear();
      });

      // Misma pausa salvadora de 800ms
      await Future.delayed(const Duration(milliseconds: 800));

      try {
        final result = await widget.state.verifyPlateByLPR(imagePath);
        if (mounted){
          setState(() {
            _result = result['message'];
            _isSuccess = result['success'];
          });
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.state.condoConfig;
    final lprEnabled = config['lprEnabled'] ?? true;
    final biometricsEnabled = config['biometricsEnabled'] ?? true;
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _isLoading ? null : _openScanner,
            icon: _isLoading 
                ? const SizedBox(
                    width: 24, 
                    height: 24, 
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  )
                : const Icon(Icons.qr_code_scanner, size: 28), 
            label: Text(
              _isLoading ? 'Procesando...' : 'Escanear Pase QR', 
              style: const TextStyle(fontSize: 18)
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(60),
              backgroundColor: Colors.indigo,
            ),
          ),
          const SizedBox(height: 24),
          const Text("Otras verificaciones:", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          if (lprEnabled) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _verifyPlate,
              icon: const Icon(Icons.directions_car_outlined),
              label: const Text('Escanear Patente (LPR)'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            ),
          ],
          if (biometricsEnabled) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _verifyFace,
              icon: const Icon(Icons.camera_front_outlined),
              label: const Text('Verificar por Rostro'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            ),
          ],
          const SizedBox(height: 24),
          if (_result.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isSuccess ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _isSuccess ? Colors.green : Colors.red),
              ),
              child: Text(
                _result, 
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _isSuccess ? Colors.green.shade900 : Colors.red.shade900,
                ),
              ),
            ),
        ],
      ),
    );
  }
}