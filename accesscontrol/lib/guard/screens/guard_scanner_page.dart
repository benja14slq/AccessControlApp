import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class GuardScannerPage extends StatefulWidget {
  const GuardScannerPage({super.key});

  @override
  State<GuardScannerPage> createState() => _GuardScannerPageState();
}

class _GuardScannerPageState extends State<GuardScannerPage> {
  final MobileScannerController _scannerController = MobileScannerController(
    // Volvemos a normal para que no retenga fotogramas en memoria
    detectionSpeed: DetectionSpeed.normal, 
    facing: CameraFacing.back,
    formats: [BarcodeFormat.qrCode],
  );

  bool _isProcessing = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear Código QR')),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              // 1. Si ya estamos procesando, rechazamos nuevas "cartas"
              if (_isProcessing) return;

              final barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                final code = barcodes.first.rawValue!;
                if (code.isNotEmpty) {
                  
                  // 2. Bloqueamos la interfaz
                  setState(() {
                    _isProcessing = true;
                  });

                  // 3. LA MAGIA SALVADORA: 
                  // Usamos Future.delayed para agendar el cierre de la pantalla
                  // en el futuro (300ms). Esto permite que el bloque de código actual
                  // termine de ejecutarse limpiamente.
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (mounted) {
                      Navigator.of(context).pop(code);
                    }
                  });

                  // 4. EL PASO CRÍTICO: Hacemos un 'return' inmediato.
                  // Esto le dice a Android: "Ya terminé con este fotograma, libéralo".
                  // Así evitamos el error de 'Unable to acquire a buffer item'.
                  return;
                }
              }
            },
          ),
          
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isProcessing ? Colors.green : Colors.white, 
                  width: 3
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          
          if (_isProcessing)
            Container(
              color: Colors.black87,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.green),
                    SizedBox(height: 24),
                    Text(
                      '¡Pase detectado!',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Retire el pase de la cámara...',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
        ],
      ),
    );
  }
}