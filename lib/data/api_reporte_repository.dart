import 'dart:io';

import '../core/app_exception.dart';
import '../models/reporte.dart';
import '../services/api_client.dart';
import 'reporte_repository.dart';

/// Implementación de [ReporteRepository] sobre la API web (MySQL).
///
/// Es la segunda implementación de la misma abstracción: la UI no cambia,
/// solo cambia de dónde salen los datos.
class ApiReporteRepository implements ReporteRepository {
  ApiReporteRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<Reporte>> obtenerTodos() => consultar();

  /// Consulta con filtros (se resuelven en SQL dentro del servidor).
  Future<List<Reporte>> consultar({
    String? especie,
    bool? atendido,
    String? texto,
  }) async {
    try {
      final parametros = <String, String>{'limit': '200'};
      if (especie != null) parametros['especie'] = especie;
      if (atendido != null) parametros['atendido'] = atendido.toString();
      if (texto != null && texto.trim().isNotEmpty) {
        parametros['q'] = texto.trim();
      }
      final consulta = Uri(queryParameters: parametros).query;
      final base = await _api.baseUrl();
      final respuesta =
          await _api.get('/api/reportes?$consulta') as Map<String, dynamic>;
      final datos = respuesta['datos'] as List<dynamic>;
      return datos
          .map((d) => Reporte.fromJson(d as Map<String, dynamic>, base))
          .toList();
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('No se pudieron leer los reportes del servidor.',
          causa: e);
    }
  }

  /// Envía el reporte y después sus archivos. Regresa el id del servidor.
  /// Es idempotente: si ya existe (mismo id_cliente) no se duplica.
  @override
  Future<int> insertar(Reporte reporte) async {
    try {
      final respuesta = await _api.post('/api/reportes', reporte.toJson())
          as Map<String, dynamic>;
      final id = respuesta['id'] as int;

      final foto = _archivoLocal(reporte.rutaImagen);
      final audio = _archivoLocal(reporte.rutaAudio);
      if (foto != null || audio != null) {
        await _api.subirArchivos(id, rutaFoto: foto, rutaAudio: audio);
      }
      return id;
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('No se pudo enviar el reporte al servidor.',
          causa: e);
    }
  }

  @override
  Future<void> actualizarAtendido(int id, bool atendido) async {
    await _api.patch('/api/reportes/$id', {'atendido': atendido});
  }

  @override
  Future<void> eliminar(int id) async {
    await _api.delete('/api/reportes/$id');
  }

  /// Un reporte del servidor con su albergue asignado.
  Future<Reporte> obtenerPorId(int id) async {
    try {
      final base = await _api.baseUrl();
      final json = await _api.get('/api/reportes/$id') as Map<String, dynamic>;
      return Reporte.fromJson(json, base);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('No se pudo leer el reporte del servidor.', causa: e);
    }
  }

  /// Asigna (o quita, con null) el albergue de un reporte.
  Future<void> asignarAlbergue(int id, int? albergueId) async {
    await _api.patch('/api/reportes/$id', {'albergue_id': albergueId});
  }

  /// Totales del servidor (GET /api/estadisticas).
  Future<Map<String, dynamic>> estadisticas() async {
    try {
      return await _api.get('/api/estadisticas') as Map<String, dynamic>;
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('No se pudieron leer las estadísticas.', causa: e);
    }
  }

  /// GET /api/salud contra una dirección dada (para "Probar conexión").
  Future<void> probarConexion(String base) async {
    await _api.get('/api/salud', base: base);
  }

  String? _archivoLocal(String? ruta) {
    if (ruta == null || ruta.startsWith('http')) return null;
    return File(ruta).existsSync() ? ruta : null;
  }
}
