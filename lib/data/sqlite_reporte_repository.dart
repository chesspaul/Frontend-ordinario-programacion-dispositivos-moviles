import '../core/app_exception.dart';
import '../core/uuid.dart';
import '../models/reporte.dart';
import 'database_helper.dart';
import 'reporte_repository.dart';

/// Implementación de [ReporteRepository] sobre SQLite.
///
/// Cada operación usa try-catch y traduce los errores técnicos a
/// [AppException] con un mensaje claro.
class SqliteReporteRepository implements ReporteRepository {
  SqliteReporteRepository(this._helper);

  final DatabaseHelper _helper;

  @override
  Future<List<Reporte>> obtenerTodos() async {
    try {
      final db = await _helper.database;
      final filas = await db.query(
        DatabaseHelper.tablaReportes,
        orderBy: 'fecha DESC',
      );
      return filas.map(Reporte.fromMap).toList();
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('No se pudieron cargar los reportes.', causa: e);
    }
  }

  @override
  Future<int> insertar(Reporte reporte) async {
    try {
      final db = await _helper.database;
      return await db.insert(DatabaseHelper.tablaReportes, reporte.toMap());
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('No se pudo guardar el reporte.', causa: e);
    }
  }

  @override
  Future<void> actualizarAtendido(int id, bool atendido) async {
    try {
      final db = await _helper.database;
      await db.update(
        DatabaseHelper.tablaReportes,
        {'atendido': atendido ? 1 : 0},
        where: 'id = ?',
        whereArgs: [id],
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('No se pudo actualizar el reporte.', causa: e);
    }
  }

  @override
  Future<void> eliminar(int id) async {
    try {
      final db = await _helper.database;
      await db.delete(
        DatabaseHelper.tablaReportes,
        where: 'id = ?',
        whereArgs: [id],
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('No se pudo eliminar el reporte.', causa: e);
    }
  }

  // ------------------------------------------------ Apoyo a la sincronización

  /// Reportes guardados en el teléfono que aún no llegan al servidor.
  Future<List<Reporte>> obtenerPendientes() async {
    try {
      final db = await _helper.database;
      final filas = await db.query(
        DatabaseHelper.tablaReportes,
        where: 'servidor_id IS NULL',
        orderBy: 'fecha ASC',
      );
      return filas.map(Reporte.fromMap).toList();
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('No se pudieron leer los reportes pendientes.',
          causa: e);
    }
  }

  /// Los reportes anteriores a la migración no tienen UUID: se les crea uno
  /// y se guarda antes de enviar (así un reintento no duplica).
  Future<Reporte> asegurarIdCliente(Reporte reporte) async {
    if (reporte.idCliente != null) return reporte;
    try {
      final db = await _helper.database;
      final nuevo = generarUuid();
      await db.update(
        DatabaseHelper.tablaReportes,
        {'id_cliente': nuevo},
        where: 'id = ?',
        whereArgs: [reporte.id],
      );
      return reporte.copyWith(idCliente: nuevo);
    } catch (e) {
      throw AppException('No se pudo preparar el reporte para enviarlo.',
          causa: e);
    }
  }

  Future<void> marcarSincronizado(int idLocal, int servidorId) async {
    try {
      final db = await _helper.database;
      await db.update(
        DatabaseHelper.tablaReportes,
        {'servidor_id': servidorId},
        where: 'id = ?',
        whereArgs: [idLocal],
      );
    } catch (e) {
      throw AppException('No se pudo marcar el reporte como enviado.',
          causa: e);
    }
  }
}
