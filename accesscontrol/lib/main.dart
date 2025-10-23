// lib/main.dart

import 'package:accesscontrol/admin/admin_shell.dart';
import 'package:accesscontrol/guard/guard_shell.dart';
import 'package:accesscontrol/resident/resident_shell.dart';
import 'package:accesscontrol/state/app_state.dart';
import 'package:accesscontrol/visit/screens/visit_pass_page.dart';
import 'package:flutter/material.dart';

// 1. Inicializamos el estado global
final AppState globalState = AppState();

void main() {
  runApp(const RoleSelectorApp());
}

// 2. RoleSelectorApp AHORA SÓLO CONSTRUYE EL MATERIAL APP
class RoleSelectorApp extends StatelessWidget {
  const RoleSelectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
      ),
      // 3. Apuntamos a un NUEVO WIDGET para la página principal
      home: const RoleSelectorHomePage(),
    );
  }
}


// 4. ESTE ES EL NUEVO WIDGET QUE CONTIENE TU SCĂFFOLD
class RoleSelectorHomePage extends StatelessWidget {
  const RoleSelectorHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // ESTE 'context' SÍ ESTÁ DEBAJO DEL MATERIAL APP Y ENCONTRARÁ EL NAVIGATOR
    return Scaffold(
      appBar: AppBar(title: const Text('Seleccionar Prototipo de Rol')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Botón para lanzar la App de Residente
          Card(
            child: ListTile(
              leading: const Icon(Icons.person_outline, color: Colors.indigo),
              title: const Text('Rol: Residente'),
              subtitle: const Text('Ver mi cuenta, generar pases, ver vehículos.'),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ResidentShell(residentState: globalState.residentState),
              )),
            ),
          ),
          const SizedBox(height: 8),
          
          // Botón para lanzar la App de Guardia
          Card(
            child: ListTile(
              leading: const Icon(Icons.security_outlined, color: Colors.blueGrey),
              title: const Text('Rol: Guardia / Conserje'),
              subtitle: const Text('Verificar pases, ver bitácora, abrir accesos.'),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => GuardShell(guardState: globalState.guardState),
              )),
            ),
          ),
          const SizedBox(height: 8),

          // Botón para lanzar la App de Administrador
          Card(
            child: ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined, color: Colors.teal),
              title: const Text('Rol: Administrador'),
              subtitle: const Text('Invitar usuarios, ver dashboard, bitácora.'),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => AdminShell(appState: globalState),
              )),
            ),
          ),
          const SizedBox(height: 8),

          // Botón para lanzar la App de Visita
          Card(
            child: ListTile(
              leading: const Icon(Icons.qr_code_2_outlined, color: Colors.orange),
              title: const Text('Rol: Visita'),
              subtitle: const Text('Ingresar código para ver mi pase.'),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => VisitPassPage(residentState: globalState.residentState),
              )),
            ),
          ),
        ],
      ),
    );
  }
}