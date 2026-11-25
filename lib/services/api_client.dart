import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/app_exception.dart';
import 'ajustes_service.dart';

/// Cliente HTTP de la API REST (Node/Express + MySQL).
///
/// Traduce todos los fallos de red y las respuestas de error del servidor a
/// [AppException] con un mensaje claro para el usuario.
class ApiClient {
  ApiClient(this._ajustes);

  final AjustesService _ajustes;
  final http.Client _http = http.Client();

  static const Duration _espera = Duration(seconds: 10);
  static const Duration _esperaArchivos = Duration(seconds: 60);

  Future<String> baseUrl() => _ajustes.leerUrlServidor();

  Future<Object?> get(String ruta, {String? base}) =>
      _json('GET', ruta, base: base);

  Future<Object?> post(String ruta, Map<String, Object?> cuerpo) =>
      _json('POST', ruta, cuerpo: cuerpo);

  Future<Object?> patch(String ruta, Map<String, Object?> cuerpo) =>
      _json('PATCH', ruta, cuerpo: cuerpo);

  Future<Object?> put(String ruta, Map<String, Object?> cuerpo) =>
      _json('PUT', ruta, cuerpo: cuerpo);

  Future<Object?> delete(String ruta) => _json('DELETE', ruta);

  Future<Object?> _json(
    String metodo,
    String ruta, {
    Map<String, Object?>? cuerpo,
    String? base,
  }) async {
    final raiz = base ?? await baseUrl();
    final Uri uri;
    try {
      uri = Uri.parse('$raiz$ruta');
    } catch (e) {
      throw AppException('La dirección del servidor no es válida.', causa: e);
    }
    final peticion = http.Request(metodo, uri);
    peticion.headers['Accept'] = 'application/json';
    if (cuerpo != null) {
      peticion.headers['Content-Type'] = 'application/json';
      peticion.body = jsonEncode(cuerpo);
    }
    return _ejecutar(() => _http.send(peticion), _espera);
  }

  /// Sube la foto y/o la nota de voz de un reporte (multipart/form-data).
  Future<Object?> subirArchivos(
    int reporteId, {
    String? rutaFoto,
    String? rutaAudio,
  }) async {
    final raiz = await baseUrl();
    final peticion = http.MultipartRequest(
      'POST',
      Uri.parse('$raiz/api/reportes/$reporteId/archivos'),
    );
    peticion.headers['Accept'] = 'application/json';
    try {
      if (rutaFoto != null) {
        peticion.files.add(await http.MultipartFile.fromPath('foto', rutaFoto));
      }
      if (rutaAudio != null) {
        peticion.files
            .add(await http.MultipartFile.fromPath('audio', rutaAudio));
      }
    } catch (e) {
      throw AppException('No se pudo leer el archivo para enviarlo.',
          causa: e);
    }
    return _ejecutar(() => _http.send(peticion), _esperaArchivos);
  }

  Future<Object?> _ejecutar(
    Future<http.StreamedResponse> Function() enviar,
    Duration espera,
  ) async {
    try {
      final respuesta = await (() async {
        final flujo = await enviar();
        return http.Response.fromStream(flujo);
      })()
          .timeout(espera);
      return _procesar(respuesta);
    } on AppException {
      rethrow;
    } on TimeoutException catch (e) {
      throw SinConexionException(
        'El servidor no respondió a tiempo. Revisa que esté encendido y la '
        'dirección en Ajustes.',
        causa: e,
      );
    } on SocketException catch (e) {
      throw SinConexionException(
        'No se pudo conectar con el servidor. Revisa la red, que la API esté '
        'encendida y la dirección en Ajustes.',
        causa: e,
      );
    } on http.ClientException catch (e) {
      throw SinConexionException(
        'No se pudo conectar con el servidor. Revisa la red, que la API esté '
        'encendida y la dirección en Ajustes.',
        causa: e,
      );
    } catch (e) {
      throw AppException('No se pudo completar la petición al servidor.',
          causa: e);
    }
  }

  Object? _procesar(http.Response respuesta) {
    final texto = utf8.decode(respuesta.bodyBytes);
    final status = respuesta.statusCode;
    if (status >= 200 && status < 300) {
      if (texto.isEmpty) return null;
      return jsonDecode(texto);
    }
    throw AppException(_mensajeDelServidor(status, texto));
  }

  /// Lee el formato de error de la API: {error: {mensaje, detalles?}}.
  String _mensajeDelServidor(int status, String texto) {
    try {
      final json = jsonDecode(texto);
      if (json is Map && json['error'] is Map) {
        final error = json['error'] as Map;
        final mensaje =
            error['mensaje']?.toString() ?? 'El servidor rechazó la petición.';
        final detalles = error['detalles'];
        if (detalles is List && detalles.isNotEmpty) {
          final lineas = detalles
              .whereType<Map>()
              .map((d) => '• ${d['campo']}: ${d['mensaje']}')
              .join('\n');
          return '$mensaje\n$lineas';
        }
        return mensaje;
      }
    } catch (_) {
      // Respuesta que no es JSON: se usa el mensaje genérico.
    }
    return 'El servidor respondió con el error $status.';
  }
}
