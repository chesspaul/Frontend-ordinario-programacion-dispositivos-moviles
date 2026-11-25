import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../core/app_exception.dart';

/// Abre y crea la base de datos SQLite (Singleton).
///
/// Solo se encarga de la conexión y del esquema; las consultas viven en el
/// repositorio (SRP).
class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static const String _nombreDb = 'patitas.db';
  static const int _version = 2;
  static const String tablaReportes = 'reportes';

  Database? _db;

  Future<Database> get database async {
    final existente = _db;
    if (existente != null) return existente;
    try {
      final ruta = p.join(await getDatabasesPath(), _nombreDb);
      final abierta = await openDatabase(
        ruta,
        version: _version,
        onCreate: _crearTablas,
        onUpgrade: _migrar,
      );
      _db = abierta;
      return abierta;
    } catch (e) {
      throw AppException('No se pudo abrir la base de datos local.', causa: e);
    }
  }

  Future<void> _crearTablas(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tablaReportes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        especie TEXT NOT NULL,
        estado TEXT NOT NULL,
        urgencia INTEGER NOT NULL,
        descripcion TEXT NOT NULL,
        ruta_imagen TEXT,
        ruta_audio TEXT,
        latitud REAL NOT NULL,
        longitud REAL NOT NULL,
        fecha INTEGER NOT NULL,
        atendido INTEGER NOT NULL DEFAULT 0,
        id_cliente TEXT,
        servidor_id INTEGER,
        cantidad_animales INTEGER NOT NULL DEFAULT 1,
        tiene_collar INTEGER NOT NULL DEFAULT 0,
        fecha_avistamiento INTEGER
      )
    ''');
  }

  /// v1 -> v2: columnas para la comunicación con el servidor y los nuevos
  /// campos del formulario. Los reportes existentes se conservan.
  Future<void> _migrar(Database db, int anterior, int nueva) async {
    if (anterior < 2) {
      await db.execute('ALTER TABLE $tablaReportes ADD COLUMN id_cliente TEXT');
      await db.execute(
          'ALTER TABLE $tablaReportes ADD COLUMN servidor_id INTEGER');
      await db.execute('ALTER TABLE $tablaReportes '
          'ADD COLUMN cantidad_animales INTEGER NOT NULL DEFAULT 1');
      await db.execute('ALTER TABLE $tablaReportes '
          'ADD COLUMN tiene_collar INTEGER NOT NULL DEFAULT 0');
      await db.execute(
          'ALTER TABLE $tablaReportes ADD COLUMN fecha_avistamiento INTEGER');
    }
  }
}
