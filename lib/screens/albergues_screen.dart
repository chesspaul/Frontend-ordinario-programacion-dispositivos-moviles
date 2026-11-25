import 'package:flutter/material.dart';

import '../app/inyector.dart';
import '../app/rutas.dart';
import '../core/app_exception.dart';
import '../models/albergue.dart';

/// Albergues registrados en MySQL, en una cuadrícula (GridView).
class AlberguesScreen extends StatefulWidget {
  const AlberguesScreen({super.key});

  @override
  State<AlberguesScreen> createState() => _AlberguesScreenState();
}

class _AlberguesScreenState extends State<AlberguesScreen> {
  final _repositorio = Inyector.albergueRepository;

  late Future<List<Albergue>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _repositorio.obtenerTodos();
  }

  void _recargar() {
    setState(() {
      _futuro = _repositorio.obtenerTodos();
    });
  }

  /// Pasa el albergue a la pantalla del formulario (o null para crear uno).
  Future<void> _abrirFormulario([Albergue? albergue]) async {
    final cambio = await Navigator.pushNamed(
      context,
      Rutas.albergue,
      arguments: albergue,
    );
    if (cambio == true && mounted) _recargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Albergues'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
            onPressed: _recargar,
          ),
        ],
      ),
      body: FutureBuilder<List<Albergue>>(
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
          if (datos.isEmpty) {
            return const Center(
              child: Text('Aún no hay albergues. Toca "Nuevo albergue".'),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 240,
              mainAxisExtent: 168,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: datos.length,
            itemBuilder: (context, indice) => _TarjetaAlbergue(
              albergue: datos[indice],
              onTap: () => _abrirFormulario(datos[indice]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        icon: const Icon(Icons.add_home_work_outlined),
        label: const Text('Nuevo albergue'),
      ),
    );
  }
}

class _TarjetaAlbergue extends StatelessWidget {
  const _TarjetaAlbergue({required this.albergue, required this.onTap});

  final Albergue albergue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: esquema.primaryContainer,
                child: Icon(Icons.home_work, color: esquema.onPrimaryContainer),
              ),
              const SizedBox(height: 8),
              Text(
                albergue.nombre,
                style: textos.titleSmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(albergue.zona, style: textos.bodySmall),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 14),
                  const SizedBox(width: 4),
                  Text(albergue.telefono, style: textos.labelMedium),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                albergue.totalReportes == 1
                    ? '1 reporte asignado'
                    : '${albergue.totalReportes} reportes asignados',
                style: textos.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
