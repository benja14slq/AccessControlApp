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

  void _verify() {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) return;
    
    final result = widget.state.verifyPass(code);
    setState(() {
      _result = result;
      _isSuccess = result.startsWith('PASE AUTORIZADO');
    });
    _codeCtrl.clear();
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
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _verify, 
            icon: const Icon(Icons.check_circle_outline), 
            label: const Text('Verificar Pase'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
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
          // Botón de "Escanear QR" (simulado)
          OutlinedButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Simulación de escáner QR'))), 
            icon: const Icon(Icons.qr_code_scanner), 
            label: const Text('Escanear QR'),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          ),
        ],
      ),
    );
  }
}