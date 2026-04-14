import 'package:accesscontrol/state/app_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RegisterGuardPage extends StatefulWidget {
  const RegisterGuardPage({super.key, required this.appState});
  final AppState appState;
  
  @override
  State<RegisterGuardPage> createState() => _RegisterGuardPageState();
}

class _RegisterGuardPageState extends State<RegisterGuardPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _isLoading = false;
  bool _emailVerified = false;
  QueryDocumentSnapshot? _pendingGuardDoc;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _nameCtrl.dispose();
    _lastNameCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _verifyEmail() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un email válido.'))
      );
      return;
    }

    setState(() => _isLoading = true);

    try{
      final query = await FirebaseFirestore.instance
          .collection('Guardias')
          .where('correo', isEqualTo: email)
          .where('estado', isEqualTo: 'Pendiente')
          .limit(1)
          .get();

      if (query.docs.isEmpty){
        throw Exception('Email no encontrado o ya registrado.');
      }

      final doc = query.docs.first;
      final data = doc.data() as Map<String, dynamic>;

      setState(() {
        _pendingGuardDoc = doc;
        _nameCtrl.text = data['nombre'] ?? '';
        _lastNameCtrl.text = data['apellido'] ?? '';
        _emailVerified = true;
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red)
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pendingGuardDoc == null) return;

    setState(() => _isLoading = true);

    try{
      UserCredential credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailCtrl.text.trim(), 
            password: _passCtrl.text.trim()
          );

      final guardUid = credential.user!.uid;

      await _pendingGuardDoc!.reference.update({
        'uid': guardUid,
        'estado': 'Registrado',
      });

      if (mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Cuenta de Guardia activada con éxito!'))
        );
        Navigator.of(context).pop();
      }

    } on FirebaseAuthException catch (e) {
      String errorMsg = 'Ocurrió un error. Intenta de nuevo.';
      if (e.code == 'weak-password') {
        errorMsg = 'La contraseña es muy débil (mín. 6 caracteres).';
      } else if (e.code == 'email-already-in-use') {
        errorMsg = 'El correo ya se encuentra registrado.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red)
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red)
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activar Cuenta de Guardia')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Correo (El que ingresó el Admin)'),
                keyboardType: TextInputType.emailAddress,
                enabled: !_isLoading && !_emailVerified,
              ),

              if (!_emailVerified)
                const SizedBox(height: 16),

              if (!_emailVerified)
                FilledButton.icon(
                  onPressed: _isLoading ? null : _verifyEmail, 
                  icon: _isLoading ? const CircularProgressIndicator() : const Icon(Icons.verified_user_outlined),
                  label: const Text('Verificar Email'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                ),
              if (_emailVerified)
                Column(
                  children: [
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      enabled: false, 
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _lastNameCtrl,
                      decoration: const InputDecoration(labelText: 'Apellido'),
                      enabled: false,
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