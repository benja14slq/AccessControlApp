import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class GuardScannerPage extends StatefulWidget {
  const GuardScannerPage({super.key});

  @override
  State<GuardScannerPage> createState() => _GuardScannerPageState();
}

class _GuardScannerPageState extends State<GuardScannerPage> {

  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    formats: [BarcodeFormat.qrCode]
  );
  bool _isScanCompleted = false;

  @override
  void dispose(){
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
              if (_isScanCompleted) return;
              
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty){
                final String code = barcodes.first.rawValue ?? "";
                if (code.isNotEmpty){
                  setState(() => _isScanCompleted = true);
                  Navigator.of(context).pop(code);
                }
              }
            },
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}