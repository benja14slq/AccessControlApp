import 'package:accesscontrol/resident/state/resident_state.dart';
import 'package:accesscontrol/shared/utils.dart';
import 'package:flutter/material.dart';

class CreatePassPage extends StatefulWidget {
  const CreatePassPage({super.key, required this.state, required this.onCreated});
  final ResidentState state;
  final VoidCallback onCreated;

  @override
  State<CreatePassPage> createState() => _CreatePassPageState();
}

class _CreatePassPageState extends State<CreatePassPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController(); // <-- NUEVO
  final _rutCtrl = TextEditingController();      // <-- Renombrado (antes _idCtrl)
  final _phoneCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  DateTime dateTime = DateTime.now().add(const Duration(hours: 1));
  bool _isLoading = false;

  bool _hasVehicle = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _lastNameCtrl.dispose(); // <-- NUEVO
    _rutCtrl.dispose();
    _phoneCtrl.dispose();
    _plateCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final d = await showDatePicker(
      context: context,
      initialDate: dateTime, 
      firstDate: DateTime.now(), 
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d == null) return;
    final t = await showTimePicker(
      context: context, 
      initialTime: TimeOfDay.fromDateTime(dateTime),
    );
    if (t == null) return;
    setState (() => dateTime = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    try {
      final String? plateValue = _hasVehicle
          ? (_plateCtrl.text.trim().isEmpty ? null : _plateCtrl.text.trim().toUpperCase())
          : null;

      await widget.state.createVisit(
        visitorName: _nameCtrl.text.trim(),
        visitorLastName: _lastNameCtrl.text.trim(),
        rut: _rutCtrl.text.trim().isEmpty ? null : _rutCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        plate: plateValue, // <-- Pasa el valor condicional
        scheduledAt: dateTime,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pase creado con éxito.'))
        );
      }
      widget.onCreated();

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear pase: $e'), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Nuevo pase de visita', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nombre del visitante'),
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingrese el nombre' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _lastNameCtrl,
              decoration: const InputDecoration(labelText: 'Apellido del visitante'),
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingrese el apellido' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _rutCtrl, 
              decoration: const InputDecoration(labelText: 'RUT (opcional)')
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneCtrl, 
              keyboardType: TextInputType.phone, 
              decoration: const InputDecoration(labelText: 'Teléfono (opcional)')
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('¿Ingresa con vehículo?'),
              value: _hasVehicle,
              onChanged: (bool newValue) {
                setState(() {
                  _hasVehicle = newValue;
                  // Si apagan el switch, limpia el campo de patente
                  if (!_hasVehicle) {
                    _plateCtrl.clear();
                  }
                });
              },
              contentPadding: EdgeInsets.zero,
            ),

            // --- 4. CAMPO DE PATENTE CONDICIONAL ---
            // Usamos AnimatedSwitcher para una transición suave
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: _hasVehicle
                  ? TextFormField(
                      key: const ValueKey('patente'), // Key para el AnimatedSwitcher
                      controller: _plateCtrl, 
                      textCapitalization: TextCapitalization.characters, 
                      decoration: const InputDecoration(labelText: 'Patente'),
                    )
                  : const SizedBox(key: ValueKey('no-patente')), // Placeholder
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: Text('Llegada: ${formatCompact(dateTime)}')),
              FilledButton.icon(
                onPressed: _pickDateTime, 
                icon: const Icon(Icons.event), 
                label: const Text('Cambiar')
              ),
            ]),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isLoading ? null : _submit, 
              icon: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                  : const Icon(Icons.qr_code_2), 
              label: Text(_isLoading ? 'Creando...' : 'Generar pase'), 
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48))
            ),
          ])
        )
      ),
    );
  }
}