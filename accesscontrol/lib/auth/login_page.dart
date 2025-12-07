import 'package:accesscontrol/admin/admin_shell.dart';
import 'package:accesscontrol/admin/main_admin.dart';
import 'package:accesscontrol/auth/register_admin_page.dart';
import 'package:accesscontrol/auth/register_guard_page.dart'; // <-- 1. IMPORTA LA NUEVA PÁGINA
import 'package:accesscontrol/auth/register_resident_page.dart';
import 'package:accesscontrol/guard/guard_shell.dart'; // <-- Importa el shell del guardia
import 'package:accesscontrol/guard/state/guard_state.dart'; // <-- Importa el estado (obsoleto)
import 'package:accesscontrol/resident/resident_shell.dart';
import 'package:accesscontrol/resident/state/resident_state.dart';
import 'package:accesscontrol/state/app_state.dart';
import 'package:accesscontrol/visit/screens/visit_pass_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.appState});
  final AppState appState;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;
  
  Future<void> _login() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa correo y contraseña.'))
      );
      return;
    }

    setState(() => _isLoading = true);

    try{
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(), 
        password: _passCtrl.text.trim(),
      );

      final user = credential.user;
      if (user == null){
        throw Exception('Error de autenticación.');
      }

      final uid = user.uid;

      final adminDoc = await FirebaseFirestore.instance
          .collection('Administradores')
          .doc(uid)
          .get();

      if (adminDoc.exists){
        await widget.appState.adminState.loadAdminData();
        if(!mounted) return;
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => AdminApp(appState: widget.appState)
        ));
        return;
      }

      final residentQuery = await FirebaseFirestore.instance
          .collection('Residentes')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();

      if (residentQuery.docs.isNotEmpty) {
        if (!mounted) return;

        final realResidentState = ResidentState(uid: uid);

        await realResidentState.init();
        
        if (!mounted) return; // Comprueba 'mounted' de nuevo por si acaso
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => ResidentShell(residentState: realResidentState), 
        ));
        return;
      }

      final guardQuery = await FirebaseFirestore.instance
          .collection('Guardias')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();

      if (guardQuery.docs.isNotEmpty){
        if (!mounted) return;
        final realGuardState = GuardState(uid: uid);
        await realGuardState.init();

        if (!mounted) return;
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          // Le pasamos el estado real al Shell
          builder: (_) => GuardShell(guardState: realGuardState), 
        ));
        return;
      }

      await FirebaseAuth.instance.signOut();
      throw Exception('Usuario autenticado pero sin rol asignado.');

    } on FirebaseAuthException catch (e) {
      // 5. Manejar errores de autenticación
      String errorMsg = 'Error desconocido. Intenta de nuevo.';
      if (e.code == 'user-not-found' || e.code == 'INVALID_LOGIN_CREDENTIALS') {
        errorMsg = 'Correo o contraseña incorrectos.';
      } else if (e.code == 'wrong-password') {
        errorMsg = 'Correo o contraseña incorrectos.';
      } else if (e.code == 'invalid-email') {
        errorMsg = 'El formato del correo no es válido.';
      }

      if (mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red)
        );
      }
    } catch (e){
      if (mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) {
        setState (() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bienvenido')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Iniciar Sesión', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Correo Electrónico'),
              keyboardType: TextInputType.emailAddress,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passCtrl,
              decoration: const InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _login,
              icon: _isLoading
                ? Container(
                    width: 24,
                    height: 24,
                    padding: const EdgeInsets.all(2.0),
                    child: const CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                  )
                : const Icon(Icons.login),
              label: Text(_isLoading ? 'Iniciando...' : 'Iniciar Sesión'),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            
            // --- Opciones de Registro y Visita ---
            
            OutlinedButton(
              onPressed: _isLoading ? null : () { // Deshabilita mientras carga
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => RegisterAdminPage(appState: widget.appState),
                ));
              },
              child: const Text('Crear cuenta de Administrador'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _isLoading ? null : () { // Deshabilita mientras carga
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => RegisterResidentPage(appState: widget.appState),
                ));
              },
              child: const Text('Activar mi cuenta de Residente'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _isLoading ? null : () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => RegisterGuardPage(appState: widget.appState),
                ));
              },
              child: const Text('Activar mi cuenta de Guardia'),
            ),
          ],
        ),
      ),
    );
  }
}