import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/app_exception.dart';

/// Ajustes de la app guardados en un ARCHIVO PLANO (ajustes.json) dentro del
/// almacenamiento de la app: la dirección del servidor.
class AjustesService {
  /// Funciona con `adb reverse tcp:3000 tcp:3000` (celular por USB).
  static const String urlPorDefecto = 'http://localhost:3000';

  String? _cache;

  Future<File> _archivo() async {
    final carpeta = await getApplicationDocumentsDirectory();
    return File(p.join(carpeta.path, 'ajustes.json'));
  }

  /// Quita espacios y diagonales finales: "http://x:3000/ " -> "http://x:3000".
  static String normalizar(String url) {
    var limpia = url.trim();
    while (limpia.endsWith('/')) {
      limpia = limpia.substring(0, limpia.length - 1);
    }
    return limpia;
  }

  Future<String> leerUrlServidor() async {
    final guardada = _cache;
    if (guardada != null) return guardada;
    var url = urlPorDefecto;
    try {
      final archivo = await _archivo();
      if (await archivo.exists()) {
        final contenido = jsonDecode(await archivo.readAsString());
        if (contenido is Map && contenido['servidor_url'] is String) {
          url = contenido['servidor_url'] as String;
        }
      }
    } catch (_) {
      // Archivo ausente o dañado: se usa la dirección por defecto.
    }
    _cache = url;
    return url;
  }

  Future<void> guardarUrlServidor(String url) async {
    final limpia = normalizar(url);
    try {
      final archivo = await _archivo();
      await archivo.writeAsString(jsonEncode({'servidor_url': limpia}));
      _cache = limpia;
    } catch (e) {
      throw AppException('No se pudo guardar el ajuste.', causa: e);
    }
  }
}
