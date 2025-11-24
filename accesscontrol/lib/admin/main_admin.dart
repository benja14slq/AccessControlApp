import 'package:accesscontrol/admin/admin_shell.dart';
import 'package:accesscontrol/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdminApp extends StatelessWidget {
  const AdminApp({super.key, required this.appState});
  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: appState.adminState,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Condominio — Admin',
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.teal,
          brightness: Brightness.light,
        ),
        home: AdminShell(appState: appState),
      ),
    );
  }
}