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
    formats: [BarcodeFormat.qrCode],
  );

  String? _foundCode;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear Código QR')),
      body: _foundCode != null 
          ? _buildLoadingScreen() 
          : _buildScannerWidget(),
    );
  }

  Widget _buildScannerWidget() {
    return Stack(
      children: [
        MobileScanner(
          controller: _scannerController,
          onDetect: (capture) async {
            if (_foundCode != null) return;

            final barcodes = capture.barcodes;
            if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
              final code = barcodes.first.rawValue!;
              if (code.isNotEmpty) {
                
                setState(() => _foundCode = code);

                // Esperamos medio segundo para que la cámara muera completamente de la RAM
                await Future.delayed(const Duration(milliseconds: 500));

                if (mounted) {
                  Navigator.of(context).pop(code);
                }
              }
            }
          },
        ),
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 3),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingScreen() {
    return Container(
      color: Colors.black87,
      width: double.infinity,
      height: double.infinity,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.green),
          SizedBox(height: 24),
          Text(
            '¡Código detectado!',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Cerrando escáner...', style: TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }
}