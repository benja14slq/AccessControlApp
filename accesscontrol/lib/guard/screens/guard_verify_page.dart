import 'package:accesscontrol/guard/screens/guard_scanner_page.dart';
import 'package:accesscontrol/guard/state/guard_state.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
    if (code.isEmpty || _isLoading) return;
    
    setState(() {
      _isLoading = true;
      _result = '';
      _codeCtrl.text = code;
    });
    
    // 3. Llama a la función async del estado
    final result = await widget.state.verifyPass(code);
    
    // 4. Actualiza la UI
    if (mounted) {
      setState(() {
        _result = result;
        _isSuccess = result.startsWith('PASE AUTORIZADO');
        _isLoading = false;
      });
    }
  }

  Future<void> _openScanner() async {
    final scannedCode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const GuardScannerPage()),
    );

    if (scannedCode != null && scannedCode.isNotEmpty){
      _verify(scannedCode);
    }
  }

  Future<void> _verifyFace() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _result = '';
      _codeCtrl.clear(); // Limpiamos el campo de texto
    });

    final result = await widget.state.verifyFaceByImage();

    if (mounted) {
      setState(() {
        _result = result['message'];
        _isSuccess = result['success'];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _codeCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(labelText: 'Ingresar código de pase'),
            onSubmitted: (_) => _verify(),
            enabled: !_isLoading,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _isLoading ? null : () => _verify(), 
            icon: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check_circle_outline),
            label: const Text('Verificar Pase'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _isLoading ? null : _verifyFace,
            icon: const Icon(Icons.camera_front_outlined),  
            label: const Text('Verificar por Rostro'),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          ),
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
          
          const Spacer(),
          OutlinedButton.icon(
            onPressed: _isLoading ? null : _openScanner, 
            icon: const Icon(Icons.qr_code_scanner), 
            label: const Text('Escanear QR (Pase de visita)'),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          ),
        ],
      ),
    );
  }
}