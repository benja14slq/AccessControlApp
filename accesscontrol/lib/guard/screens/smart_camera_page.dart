import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class SmartCameraPage extends StatefulWidget {
  final bool isFrontCamera;
  final String title;

  const SmartCameraPage({
    super.key, 
    required this.isFrontCamera,
    required this.title,
  });

  @override
  State<SmartCameraPage> createState() => _SmartCameraPageState();
}

class _SmartCameraPageState extends State<SmartCameraPage> {
  CameraController? _controller;
  bool _isInitializing = true;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      // 1. Obtener todas las cámaras del dispositivo
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw Exception("No se encontraron cámaras");

      // 2. Elegir frontal o trasera según lo que pidamos (Rostro = Frontal, LPR = Trasera)
      final cameraDir = widget.isFrontCamera ? CameraLensDirection.front : CameraLensDirection.back;
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == cameraDir,
        orElse: () => cameras.first,
      );

      // 3. Inicializar con Resolución MEDIA (Ideal para ML Kit y AWS, cero lag)
      _controller = CameraController(
        camera, 
        ResolutionPreset.medium,
        enableAudio: false, // No necesitamos audio, ahorra memoria
      );

      await _controller!.initialize();
      
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    } catch (e) {
      print("Error iniciando cámara: $e");
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _takePicture() async {
    if (_isCapturing || _controller == null || !_controller!.value.isInitialized) return;

    setState(() => _isCapturing = true);

    try {
      // 1. Tomamos la foto
      final XFile photo = await _controller!.takePicture();
      
      // 2. IMPORTANTE: No llamamos a _controller!.dispose() aquí.
      // Dejamos que el override de dispose() abajo se encargue de eso.
      // Así evitamos el CameraException del buildPreview.

      // 3. Devolvemos la ruta a la pantalla de botones
      if (mounted) {
        Navigator.pop(context, photo.path);
      }
    } catch (e) {
      print("Error capturando: $e");
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(title: Text(widget.title), backgroundColor: Colors.black),
        body: const Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title), 
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Vista previa de la cámara a pantalla completa
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: CameraPreview(_controller!),
          ),
          
          // Capa de opacidad si está procesando la foto
          if (_isCapturing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.green),
                    SizedBox(height: 16),
                    Text("Procesando imagen...", style: TextStyle(color: Colors.white, fontSize: 18))
                  ],
                ),
              ),
            ),
            
          // Botón de captura
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: FloatingActionButton.large(
                backgroundColor: Colors.white,
                onPressed: _isCapturing ? null : _takePicture,
                child: const Icon(Icons.camera_alt, color: Colors.black, size: 40),
              ),
            ),
          )
        ],
      ),
    );
  }
}