import '../core/app_exception.dart';
import '../models/albergue.dart';
import '../services/api_client.dart';

/// Acceso a los albergues en MySQL a través de la API web.
class ApiAlbergueRepository {
  ApiAlbergueRepository(this._api);

  final ApiClient _api;

  Future<List<Albergue>> obtenerTodos() async {
    try {
      final respuesta = await _api.get('/api/albergues') as Map<String, dynamic>;
      final datos = respuesta['datos'] as List<dynamic>;
      return datos
          .map((d) => Albergue.fromJson(d as Map<String, dynamic>))
          .toList();
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('No se pudieron leer los albergues.', causa: e);
    }
  }

  /// Crea (POST) si no tiene id, o edita (PUT) si ya existe.
  Future<void> guardar(Albergue albergue) async {
    if (albergue.id == null) {
      await _api.post('/api/albergues', albergue.toJson());
    } else {
      await _api.put('/api/albergues/${albergue.id}', albergue.toJson());
    }
  }

  Future<void> eliminar(int id) async {
    await _api.delete('/api/albergues/$id');
  }
}
