import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/inyector.dart';
import '../core/app_exception.dart';
import '../models/albergue.dart';

/// Formulario para crear o editar un albergue.
/// Si recibe un [albergue], entra en modo edición (información que viaja
/// entre pantallas por los argumentos de la ruta).
class AlbergueFormScreen extends StatefulWidget {
  const AlbergueFormScreen({super.key, this.albergue});

  final Albergue? albergue;

  @override
  State<AlbergueFormScreen> createState() => _AlbergueFormScreenState();
}

class _AlbergueFormScreenState extends State<AlbergueFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _zonaCtrl = TextEditingController();
  final _repositorio = Inyector.albergueRepository;

  bool _guardando = false;

  bool get _editando => widget.albergue != null;

  @override
  void initState() {
    super.initState();
    final a = widget.albergue;
    if (a != null) {
      _nombreCtrl.text = a.nombre;
      _telefonoCtrl.text = a.telefono;
      _zonaCtrl.text = a.zona;
    }
  }

  void _aviso(String mensaje) {
    if (!mounted) return;
    final mensajero = ScaffoldMessenger.of(context);
    mensajero.hideCurrentSnackBar();
    mensajero.showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      await _repositorio.guardar(Albergue(
        id: widget.albergue?.id,
        nombre: _nombreCtrl.text.trim(),
        telefono: _telefonoCtrl.text.trim(),
        zona: _zonaCtrl.text.trim(),
      ));
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _guardando = false);
      _aviso(mensajeDeError(e));
    }
  }

  Future<void> _eliminar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('¿Eliminar albergue?'),
        content: const Text(
          'Los reportes asignados a este albergue quedarán sin albergue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogo, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogo, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      await _repositorio.eliminar(widget.albergue!.id!);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _aviso(mensajeDeError(e));
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _zonaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar albergue' : 'Nuevo albergue'),
        actions: [
          if (_editando)
            IconButton(
              tooltip: 'Eliminar',
              icon: const Icon(Icons.delete_outline),
              onPressed: _eliminar,
            ),
        ],
      ),
      body: IgnorePointer(
        ignoring: _guardando,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _nombreCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nombre del albergue',
                  prefixIcon: Icon(Icons.home_work_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (valor) {
                  final n = (valor ?? '').trim().length;
                  if (n < 3 || n > 120) return 'Escribe de 3 a 120 caracteres.';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telefonoCtrl,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: const InputDecoration(
                  labelText: 'Teléfono (10 dígitos)',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (valor) {
                  if ((valor ?? '').trim().length != 10) {
                    return 'El teléfono debe tener exactamente 10 dígitos.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _zonaCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Zona o alcaldía',
                  prefixIcon: Icon(Icons.place_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (valor) {
                  final n = (valor ?? '').trim().length;
                  if (n < 2 || n > 80) return 'Escribe de 2 a 80 caracteres.';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _guardando ? null : _guardar,
                icon: _guardando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_guardando ? 'Guardando...' : 'Guardar albergue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
