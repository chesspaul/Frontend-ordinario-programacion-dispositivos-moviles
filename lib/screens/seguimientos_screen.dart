import 'package:flutter/material.dart';

import '../app/inyector.dart';
import '../core/app_exception.dart';
import '../core/formato.dart';
import '../models/albergue.dart';
import '../models/catalogos.dart';
import '../models/reporte.dart';
import '../models/seguimiento.dart';

/// Datos que necesita la pantalla, cargados juntos desde el servidor.
class _Datos {
  const _Datos(this.reporte, this.seguimientos, this.albergues);

  final Reporte reporte;
  final List<Seguimiento> seguimientos;
  final List<Albergue> albergues;
}

/// Lo que captura el formulario de seguimiento.
class _NuevoSeguimiento {
  const _NuevoSeguimiento({
    required this.nota,
    required this.fecha,
    required this.estadoNuevo,
    required this.requiereTraslado,
  });

  final String nota;
  final DateTime fecha;
  final String? estadoNuevo;
  final bool requiereTraslado;
}

/// Albergue asignado y bitácora de seguimiento de un reporte del servidor.
class SeguimientosScreen extends StatefulWidget {
  const SeguimientosScreen({super.key, required this.reporte});

  final Reporte reporte;

  @override
  State<SeguimientosScreen> createState() => _SeguimientosScreenState();
}

class _SeguimientosScreenState extends State<SeguimientosScreen> {
  final _reportes = Inyector.apiRepository;
  final _seguimientos = Inyector.seguimientoRepository;
  final _albergues = Inyector.albergueRepository;

  late Future<_Datos> _futuro;

  int get _servidorId => widget.reporte.servidorId!;

  @override
  void initState() {
    super.initState();
    _futuro = _cargar();
  }

  Future<_Datos> _cargar() async {
    final reporte = await _reportes.obtenerPorId(_servidorId);
    final lista = await _seguimientos.listar(_servidorId);
    final albergues = await _albergues.obtenerTodos();
    return _Datos(reporte, lista, albergues);
  }

  void _recargar() {
    setState(() {
      _futuro = _cargar();
    });
  }

  void _aviso(String mensaje) {
    if (!mounted) return;
    final mensajero = ScaffoldMessenger.of(context);
    mensajero.hideCurrentSnackBar();
    mensajero.showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Future<void> _asignarAlbergue(int? albergueId) async {
    try {
      await _reportes.asignarAlbergue(_servidorId, albergueId);
      _aviso(albergueId == null ? 'Albergue quitado' : 'Albergue asignado');
      if (mounted) _recargar();
    } catch (e) {
      _aviso(mensajeDeError(e));
      if (mounted) _recargar();
    }
  }

  Future<void> _agregar() async {
    final datos = await showModalBottomSheet<_NuevoSeguimiento>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (hoja) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(hoja).viewInsets.bottom),
        child: const _FormularioSeguimiento(),
      ),
    );
    if (datos == null) return;
    try {
      await _seguimientos.crear(
        _servidorId,
        nota: datos.nota,
        fecha: datos.fecha,
        estadoNuevo: datos.estadoNuevo,
        requiereTraslado: datos.requiereTraslado,
      );
      _aviso('Seguimiento guardado');
      if (mounted) _recargar();
    } catch (e) {
      _aviso(mensajeDeError(e));
    }
  }

  Future<void> _eliminar(Seguimiento seguimiento) async {
    try {
      await _seguimientos.eliminar(seguimiento.id!);
      _aviso('Seguimiento eliminado');
      if (mounted) _recargar();
    } catch (e) {
      _aviso(mensajeDeError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final r = widget.reporte;

    return Scaffold(
      appBar: AppBar(
        title: Text('Seguimiento · ${r.especie}'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
            onPressed: _recargar,
          ),
        ],
      ),
      body: FutureBuilder<_Datos>(
        future: _futuro,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cloud_off,
                      size: 56,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      mensajeDeError(snapshot.error!),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _recargar,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }
          final datos = snapshot.data;
          if (datos == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final actual = datos.reporte;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              Text(
                '${actual.especie} · ${actual.estado}',
                style: textos.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                actual.descripcion,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),
              Text('Albergue asignado', style: textos.titleMedium),
              const SizedBox(height: 8),
              DropdownButtonFormField<int?>(
                key: ValueKey('albergue-${actual.albergueId}'),
                initialValue: actual.albergueId,
                isExpanded: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.home_work_outlined),
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Sin asignar'),
                  ),
                  for (final a in datos.albergues)
                    DropdownMenuItem<int?>(
                      value: a.id,
                      child: Text(
                        '${a.nombre} (${a.zona})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: _asignarAlbergue,
              ),
              const SizedBox(height: 24),
              Text('Bitácora', style: textos.titleMedium),
              const SizedBox(height: 8),
              if (datos.seguimientos.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Aún no hay seguimientos. Toca "Agregar seguimiento".',
                    ),
                  ),
                )
              else
                for (final s in datos.seguimientos)
                  Card(
                    child: ListTile(
                      leading: Icon(
                        s.requiereTraslado
                            ? Icons.local_shipping_outlined
                            : Icons.note_alt_outlined,
                      ),
                      title: Text(s.nota),
                      subtitle: Text(
                        '${formatearDia(s.fecha)}'
                        '${s.estadoNuevo != null ? ' · Estado: ${s.estadoNuevo}' : ''}'
                        '${s.requiereTraslado ? ' · Requiere traslado' : ''}',
                      ),
                      trailing: IconButton(
                        tooltip: 'Eliminar',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _eliminar(s),
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _agregar,
        icon: const Icon(Icons.add_comment_outlined),
        label: const Text('Agregar seguimiento'),
      ),
    );
  }
}

/// Formulario (en hoja inferior): texto, fecha, lista desplegable y switch.
class _FormularioSeguimiento extends StatefulWidget {
  const _FormularioSeguimiento();

  @override
  State<_FormularioSeguimiento> createState() => _FormularioSeguimientoState();
}

class _FormularioSeguimientoState extends State<_FormularioSeguimiento> {
  final _formKey = GlobalKey<FormState>();
  final _notaCtrl = TextEditingController();

  DateTime _fecha = DateTime.now();
  String? _estadoNuevo;
  bool _requiereTraslado = false;

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(hoy.year - 1),
      lastDate: hoy,
      helpText: 'Fecha del seguimiento',
    );
    if (elegida != null && mounted) setState(() => _fecha = elegida);
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _NuevoSeguimiento(
        nota: _notaCtrl.text.trim(),
        fecha: _fecha,
        estadoNuevo: _estadoNuevo,
        requiereTraslado: _requiereTraslado,
      ),
    );
  }

  @override
  void dispose() {
    _notaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Nuevo seguimiento',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notaCtrl,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nota',
                hintText: 'Qué pasó con el animal...',
                border: OutlineInputBorder(),
              ),
              validator: (valor) {
                final n = (valor ?? '').trim().length;
                if (n < 3 || n > 500) return 'Escribe de 3 a 500 caracteres.';
                return null;
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: const Text('Fecha'),
              subtitle: Text(formatearDia(_fecha)),
              trailing: const Icon(Icons.edit_calendar_outlined),
              onTap: _elegirFecha,
            ),
            DropdownButtonFormField<String?>(
              initialValue: _estadoNuevo,
              decoration: const InputDecoration(
                labelText: 'Cambiar estado del animal',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Sin cambio'),
                ),
                for (final e in estados)
                  DropdownMenuItem<String?>(value: e, child: Text(e)),
              ],
              onChanged: (valor) => setState(() => _estadoNuevo = valor),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Requiere traslado'),
              value: _requiereTraslado,
              onChanged: (valor) => setState(() => _requiereTraslado = valor),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _guardar,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Guardar seguimiento'),
            ),
          ],
        ),
      ),
    );
  }
}
