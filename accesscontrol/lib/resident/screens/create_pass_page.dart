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
  final _idCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  DateTime dateTime = DateTime.now().add(const Duration(hours: 1));

  @override
  void dispose() {
    _nameCtrl.dispose();
    _idCtrl.dispose();
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

  void _submit(){
    if (!_formKey.currentState!.validate()) return;
    widget.state.createVisit(
      visitorName: _nameCtrl.text.trim(),
      visitorId: _idCtrl.text.trim().isEmpty ? null : _idCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      plate: _plateCtrl.text.trim().isEmpty ? null : _plateCtrl.text.trim(),
      scheduledAt: dateTime,
    );
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pase creado. Comparte el código desde Mis Visitas.')));
    widget.onCreated();
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
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingrese el nombre' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(controller: _idCtrl, decoration: const InputDecoration(labelText: 'RUT / ID (opcional)')),
            const SizedBox(height: 8),
            TextFormField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Teléfono (opcional)')),
            const SizedBox(height: 8),
            TextFormField(controller: _plateCtrl, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Patente (opcional)')),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: Text('Llegada: ${formatCompact(dateTime)}')),
              FilledButton.icon(onPressed: _pickDateTime, icon: const Icon(Icons.event), label: const Text('Cambiar')),
            ]),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: _submit, icon: const Icon(Icons.qr_code_2), label: const Text('Generar pase'), style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48))),
          ])
        )
      ),
    );
  }
}