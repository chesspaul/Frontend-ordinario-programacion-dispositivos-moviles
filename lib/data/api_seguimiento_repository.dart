import '../core/app_exception.dart';
import '../core/formato.dart';
import '../models/seguimiento.dart';
import '../services/api_client.dart';

/// Acceso a los seguimientos de un reporte en MySQL (API web).
class ApiSeguimientoRepository {
  ApiSeguimientoRepository(this._api);

  final ApiClient _api;

  Future<List<Seguimiento>> listar(int reporteId) async {
    try {
      final respuesta = await _api.get('/api/reportes/$reporteId/seguimientos')
          as Map<String, dynamic>;
      final datos = respuesta['datos'] as List<dynamic>;
      return datos
          .map((d) => Seguimiento.fromJson(d as Map<String, dynamic>))
          .toList();
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('No se pudieron leer los seguimientos.', causa: e);
    }
  }

  /// Si [estadoNuevo] no es null, el servidor cambia también el estado del
  /// reporte (en la misma transacción).
  Future<void> crear(
    int reporteId, {
    required String nota,
    required DateTime fecha,
    String? estadoNuevo,
    required bool requiereTraslado,
  }) async {
    await _api.post('/api/reportes/$reporteId/seguimientos', {
      'nota': nota,
      'fecha': formatearFechaSola(fecha),
      'estado_nuevo': estadoNuevo,
      'requiere_traslado': requiereTraslado,
    });
  }

  Future<void> eliminar(int id) async {
    await _api.delete('/api/seguimientos/$id');
  }
}
