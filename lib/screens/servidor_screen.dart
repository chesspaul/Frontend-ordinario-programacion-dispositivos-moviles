import 'package:flutter/material.dart';

import '../app/inyector.dart';
import '../app/rutas.dart';
import '../core/app_exception.dart';
import '../core/formato.dart';
import '../models/catalogos.dart';
import '../models/reporte.dart';
import '../widgets/foto_reporte.dart';
import '../widgets/reporte_card.dart';

/// Consulta los reportes guardados en MySQL a través de la API web.
/// Los filtros y la búsqueda se resuelven en el servidor (SQL).
class ServidorScreen extends StatefulWidget {
  const ServidorScreen({super.key});

  @override
  State<ServidorScreen> createState() => _ServidorScreenState();
}

class _ServidorScreenState extends State<ServidorScreen> {
  final _api = Inyector.apiRepository;
  final _busquedaCtrl = TextEditingController();

  String? _especie;
  bool _soloPendientes = false;

  late Future<List<Reporte>> _futuro;
  late Future<Map<String, dynamic>> _stats;

  @override
  void initState() {
    super.initState();
    _consultar();
  }

  void _consultar() {
    _futuro = _api.consultar(
      especie: _especie,
      atendido: _soloPendientes ? false : null,
      texto: _busquedaCtrl.text,
    );
    _stats = _api.estadisticas();
  }

  void _recargar() => setState(_consultar);

  void _aviso(String mensaje) {
    if (!mounted) return;
    final mensajero = ScaffoldMessenger.of(context);
    mensajero.hideCurrentSnackBar();
    mensajero.showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Future<void> _alternarAtendido(Reporte reporte) async {
    try {
      await _api.actualizarAtendido(reporte.id!, !reporte.atendido);
      _aviso(reporte.atendido
          ? 'Marcado como pendiente'
          : 'Marcado como atendido');
      if (mounted) _recargar();
    } catch (e) {
      _aviso(mensajeDeError(e));
    }
  }

  Future<void> _eliminar(Reporte reporte) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('¿Eliminar del servidor?'),
        content: const Text(
          'Se borrará el reporte de MySQL con sus seguimientos y archivos. '
          'La copia guardada en el teléfono no se toca.',
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
      await _api.eliminar(reporte.id!);
      _aviso('Reporte eliminado del servidor');
      if (mounted) _recargar();
    } catch (e) {
      _aviso(mensajeDeError(e));
    }
  }

  void _abrirAcciones(Reporte reporte) {
    final textos = Theme.of(context).textTheme;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (hoja) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FotoReporte(
                  ruta: reporte.rutaImagen,
                  ancho: double.infinity,
                  alto: 180,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${reporte.especie} · ${reporte.estado}',
                style: textos.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Urgencia ${etiquetaUrgencia(reporte.urgencia).toLowerCase()} · '
                '${reporte.cantidadAnimales} animal(es)'
                '${reporte.tieneCollar ? ' · con collar' : ''}',
              ),
              if (reporte.fechaAvistamiento != null)
                Text('Visto el ${formatearDia(reporte.fechaAvistamiento!)}'),
              const SizedBox(height: 8),
              Text(reporte.descripcion),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(hoja);
                    Navigator.pushNamed(
                      context,
                      Rutas.seguimientos,
                      arguments: reporte,
                    );
                  },
                  icon: const Icon(Icons.assignment_outlined),
                  label: const Text('Seguimiento y albergue'),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: () {
                        Navigator.pop(hoja);
                        _alternarAtendido(reporte);
                      },
                      icon: Icon(reporte.atendido
                          ? Icons.undo
                          : Icons.check_circle_outline),
                      label: Text(
                          reporte.atendido ? 'Pendiente' : 'Atendido'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(hoja);
                        _eliminar(reporte);
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Eliminar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes en el servidor'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
            onPressed: _recargar,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _busquedaCtrl,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _recargar(),
              decoration: InputDecoration(
                hintText: 'Buscar en la descripción...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: 'Buscar',
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _recargar,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                for (final e in [null, ...especies])
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(e ?? 'Todos'),
                      selected: _especie == e,
                      onSelected: (_) {
                        _especie = e;
                        _recargar();
                      },
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: const Text('Solo pendientes'),
                    selected: _soloPendientes,
                    onSelected: (valor) {
                      _soloPendientes = valor;
                      _recargar();
                    },
                  ),
                ),
              ],
            ),
          ),
          FutureBuilder<Map<String, dynamic>>(
            future: _stats,
            builder: (context, snapshot) {
              final datos = snapshot.data;
              if (datos == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'En MySQL: ${datos['total_reportes']} reportes · '
                  '${datos['pendientes']} pendientes · '
                  '${datos['total_albergues']} albergues',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              );
            },
          ),
          Expanded(
            child: FutureBuilder<List<Reporte>>(
              future: _futuro,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _VistaError(
                    mensaje: mensajeDeError(snapshot.error!),
                    onReintentar: _recargar,
                  );
                }
                final datos = snapshot.data;
                if (datos == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (datos.isEmpty) {
                  return const Center(
                    child: Text('No hay reportes con esos filtros.'),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    _recargar();
                    try {
                      await _futuro;
                    } catch (_) {}
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 4, bottom: 24),
                    itemCount: datos.length,
                    itemBuilder: (context, indice) {
                      final reporte = datos[indice];
                      return ReporteCard(
                        reporte: reporte,
                        conHero: false,
                        onTap: () => _abrirAcciones(reporte),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _VistaError extends StatelessWidget {
  const _VistaError({required this.mensaje, required this.onReintentar});

  final String mensaje;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
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
            Text(mensaje, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onReintentar,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
