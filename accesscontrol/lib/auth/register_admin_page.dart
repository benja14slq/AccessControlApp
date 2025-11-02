import 'package:accesscontrol/state/app_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RegisterAdminPage extends StatefulWidget {
  const RegisterAdminPage({super.key, required this.appState});
  final AppState appState;
  
  @override
  State<RegisterAdminPage> createState() => _RegisterAdminPageState();
}

class _RegisterAdminPageState extends State<RegisterAdminPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();     
  final _lastNameCtrl = TextEditingController();   
  final _condoNameCtrl = TextEditingController(); 
  final _passCtrl = TextEditingController();     
  final _confirmPassCtrl = TextEditingController();

  String? _selectedCondoTypeId;
  bool _isLoading = false;

  void dispose() {
    // Limpia todos los controllers
    _emailCtrl.dispose();
    _nameCtrl.dispose();
    _lastNameCtrl.dispose();
    _condoNameCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }
  
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCondoTypeId == null){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona un tipo de entorno'))
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = _emailCtrl.text.trim();
      final password = _passCtrl.text.trim();

      UserCredential userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);

      final uid = userCredential.user!.uid;

      final adminData = {
        'uid': uid,
        'email': email,
        'nombre': _nameCtrl.text.trim(),
        'apellido': _lastNameCtrl.text.trim(),
        'nombreCondominio': _condoNameCtrl.text.trim(),
        'tipoCondominioId': _selectedCondoTypeId,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('Administradores')
          .doc(uid)
          .set(adminData);

      if (mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Administrador registrado con éxito.'))
        );
        Navigator.of(context).pop();
      }

    } on FirebaseAuthException catch (e) {
      String errorMsg = 'Ocurrio un error. Intenta de nuevo.';
      if (e.code == 'weak-password'){
        errorMsg = 'La contraseña es muy débil.';
      } else if (e.code == 'email-already-in-use'){
        errorMsg = 'El correo ya se encuentra registrado.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red)
      );
    } catch (e){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red)
      );
    } finally {
      if (mounted){
        setState (() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = widget.appState;
    return Scaffold(
      appBar: AppBar(title: const Text('Registro de Administrador')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Correo'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v == null || !v.contains('@')) ? 'Email inválido' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) => (v == null || v.isEmpty) ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _lastNameCtrl,
                decoration: const InputDecoration(labelText: 'Apellido'),
                validator: (v) => (v == null || v.isEmpty) ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _condoNameCtrl,
                decoration: const InputDecoration(labelText: 'Nombre del Condominio'),
                validator: (v) => (v == null || v.isEmpty) ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 8),
              appState.isLoadingTypes
                ? const Center(child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ))
                : DropdownButtonFormField<String>(
                    value: _selectedCondoTypeId,
                    decoration: const InputDecoration(labelText: 'Tipo de Entorno'),
                    // Valida que se haya seleccionado uno
                    validator: (value) => value == null ? 'Selecciona un tipo' : null,
                    items: appState.condoTypes.map((type) {
                      return DropdownMenuItem(
                        value: type.id, // Guardamos el ID del documento
                        child: Text(type.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedCondoTypeId = value);
                    },
                  ),
              
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passCtrl,
                decoration: const InputDecoration(labelText: 'Contraseña'),
                obscureText: true,
                validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _confirmPassCtrl,
                decoration: const InputDecoration(labelText: 'Confirmar Contraseña'),
                obscureText: true,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Confirma la contraseña';
                  if (v != _passCtrl.text) return 'Las contraseñas no coinciden';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _isLoading ? null : _register, 
                icon: _isLoading 
                  ? Container(width: 24, height: 24, padding: const EdgeInsets.all(2.0), child: const CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                  : const Icon(Icons.app_registration),
                label: Text(_isLoading ? 'Registrando...' : 'Registrar Condominio'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              ),
              
            ],
          ),
        ),
      ),
    );
  }
}