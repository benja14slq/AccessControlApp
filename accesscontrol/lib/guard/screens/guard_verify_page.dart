import 'package:accesscontrol/guard/screens/guard_scanner_page.dart';
import 'package:accesscontrol/guard/state/guard_state.dart';
import 'package:flutter/material.dart';

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

  Future<void> _verifyQR([String? codeFromScanner]) async {
    final code = codeFromScanner ?? _codeCtrl.text.trim();
    if (code.isEmpty || _isLoading) return;
    
    setState(() {
      _isLoading = true;
      _result = '';
      _codeCtrl.text = code;
    });

    // Pausa para que la cámara del Scanner se libere correctamente
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    
    try {
      final result = await widget.state.verifyPass(code);
      if (mounted) {
        setState(() {
          _result = result;
          _isSuccess = true;
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openScanner() async {
    final scannedCode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const GuardScannerPage()),
    );

    if (scannedCode != null && scannedCode.isNotEmpty) {
      _verifyQR(scannedCode);
    }
  }

  Future<void> _verifyFace() async {
    if (_isLoading) return;

    // Abrimos cámara e interceptamos el Future
    setState(() {
      _isLoading = true;
      _result = '';
      _codeCtrl.clear();
    });

    try {
      // Abre ImagePicker desde GuardState
      final result = await widget.state.verifyFaceByImage();
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

  Future<void> _verifyPlate() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _result = '';
      _codeCtrl.clear();
    });

    try {
      final result = await widget.state.verifyPlateByLPR();
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
                    width: 24, height: 24, 
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