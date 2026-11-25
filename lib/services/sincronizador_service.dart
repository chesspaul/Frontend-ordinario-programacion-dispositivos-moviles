import '../core/app_exception.dart';
import '../data/api_reporte_repository.dart';
import '../data/sqlite_reporte_repository.dart';

/// Resultado de un intento de sincronización.
class ResultadoSync {
  const ResultadoSync({
    required this.enviados,
    required this.pendientes,
    this.error,
  });

  final int enviados;
  final int pendientes;
  final String? error;

  String get mensaje {
    if (error != null && enviados == 0) {
      return 'Guardado en el teléfono. Sin enviar al servidor: $error';
    }
    if (error != null) {
      return 'Se enviaron $enviados; quedan $pendientes pendientes: $error';
    }
    if (enviados == 0) return 'No hay reportes pendientes por enviar.';
    return enviados == 1
        ? 'Reporte enviado al servidor.'
        : '$enviados reportes enviados al servidor.';
  }
}

/// Envía al servidor los reportes guardados en SQLite (local primero).
///
/// Nunca lanza: los errores se resumen en [ResultadoSync].
class SincronizadorService {
  SincronizadorService(this._local, this._remoto);

  final SqliteReporteRepository _local;
  final ApiReporteRepository _remoto;

  Future<ResultadoSync> sincronizarPendientes() async {
    var enviados = 0;
    var pendientes = 0;
    String? error;
    try {
      final lista = await _local.obtenerPendientes();
      pendientes = lista.length;
      for (final pendiente in lista) {
        try {
          final reporte = await _local.asegurarIdCliente(pendiente);
          final servidorId = await _remoto.insertar(reporte);
          await _local.marcarSincronizado(reporte.id!, servidorId);
          enviados++;
        } on SinConexionException catch (e) {
          error = e.mensaje;
          break; // sin red: no tiene caso intentar con los demás
        } on AppException catch (e) {
          error = e.mensaje; // un reporte rechazado no frena a los demás
        }
      }
    } on AppException catch (e) {
      error = e.mensaje;
    } catch (_) {
      error = 'Ocurrió un error inesperado al sincronizar.';
    }
    return ResultadoSync(
      enviados: enviados,
      pendientes: pendientes - enviados,
      error: error,
    );
  }
}
