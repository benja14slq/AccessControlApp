import 'package:accesscontrol/state/app_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterResidentPage extends StatefulWidget {
  const RegisterResidentPage({super.key, required this.appState});
  final AppState appState;

  @override
  State<RegisterResidentPage> createState() => _RegisterResidentPageState();
}

class _RegisterResidentPageState extends State<RegisterResidentPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  
  bool _isLoading = false;
  bool _emailVerified = false; // 1. Nuevo estado para controlar la UI
  QueryDocumentSnapshot? _pendingResidentDoc; // 2. Para guardar la invitación

  @override
  void dispose() {
    // ... (dispose de todos los controllers)
    super.dispose();
  }

  // 3. NUEVA FUNCIÓN para verificar el email primero
  Future<void> _verifyEmail() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un email válido.'))
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final query = await FirebaseFirestore.instance
          .collection('Residentes') // <-- Buscamos en 'Residentes'
          .where('correo', isEqualTo: email)
          .where('estado', isEqualTo: 'Pendiente')
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        throw Exception('Email no encontrado o ya registrado.');
      }

      final doc = query.docs.first;
      final data = doc.data() as Map<String, dynamic>;

      // 4. Email verificado: guardamos el doc y rellenamos los campos
      setState(() {
        _pendingResidentDoc = doc;
        _nameCtrl.text = data['nombre'] ?? '';
        _lastNameCtrl.text = data['apellido'] ?? '';
        _emailVerified = true; // Mostramos el resto del formulario
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red)
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 5. FUNCIÓN _register() ACTUALIZADA
  Future<void> _register() async {
    // Valida solo el formulario (contraseñas)
    if (!_formKey.currentState!.validate()) return;
    if (_pendingResidentDoc == null) return; // Seguridad

    setState(() => _isLoading = true);

    try {
      final invitationData = _pendingResidentDoc!.data() as Map<String, dynamic>;
      final adminUid = invitationData['adminUid'];

      // 1. BUSCAR DATOS DEL ADMIN
      final adminDoc = await FirebaseFirestore.instance
          .collection('Administradores')
          .doc(adminUid)
          .get();
      
      if (!adminDoc.exists) {
        throw Exception('Error: El administrador que te invitó no fue encontrado.');
      }
      final adminData = adminDoc.data()!;

      // 2. CREAR USUARIO EN AUTHENTICATION
      UserCredential credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: invitationData['correo'], 
              password: _passCtrl.text.trim()
            );
      
      final residentUid = credential.user!.uid;

      // 3. ACTUALIZAR EL DOCUMENTO 'Residentes'
      // Ya no creamos un doc nuevo, actualizamos el existente
      await _pendingResidentDoc!.reference.update({
        'uid': residentUid,
        'nombreCondominio': adminData['nombreCondominio'],
        'tipoCondominioId': adminData['tipoCondominioId'],
        'estado': 'Registrado', // ¡Activamos la cuenta!
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Cuenta activada con éxito! Ya puedes iniciar sesión.'))
        );
        Navigator.of(context).pop(); // Regresa al Login
      }

    } catch (e) {
      // (Manejo de errores...)
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activar Cuenta de Residente')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Correo (invitado por tu admin)'),
                keyboardType: TextInputType.emailAddress,
                // 6. El email se deshabilita después de verificar
                enabled: !_isLoading && !_emailVerified, 
              ),
              
              // 7. Mostramos el resto del formulario CONDICIONALMENTE
              if (!_emailVerified)
                const SizedBox(height: 16),
              
              if (!_emailVerified)
                FilledButton.icon(
                  onPressed: _isLoading ? null : _verifyEmail,
                  icon: _isLoading ? const CircularProgressIndicator() : const Icon(Icons.verified_user_outlined),
                  label: const Text('Verificar Email'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                ),

              // 8. Campos que aparecen después de la verificación
              if (_emailVerified)
                Column(
                  children: [
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      enabled: false, // No se puede editar
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _lastNameCtrl,
                      decoration: const InputDecoration(labelText: 'Apellido'),
                      enabled: false, // No se puede editar
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passCtrl,
                      decoration: const InputDecoration(labelText: 'Crear Contraseña'),
                      obscureText: true,
                      enabled: !_isLoading,
                      validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _confirmPassCtrl,
                      decoration: const InputDecoration(labelText: 'Confirmar Contraseña'),
                      obscureText: true,
                      enabled: !_isLoading,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Confirme su contraseña';
                        if (v != _passCtrl.text) return 'Las contraseñas no coinciden';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _isLoading ? null : _register, 
                      icon: _isLoading 
                        ? Container(width: 24, height: 24, padding: const EdgeInsets.all(2.0), child: const CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                        : const Icon(Icons.person_add_alt_1),
                      label: Text(_isLoading ? 'Activando...' : 'Activar Cuenta'),
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    )
                  ],
                )
            ],
          )
        ),
      ),
    );
  }
}