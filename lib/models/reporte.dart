import '../core/formato.dart';

/// Un reporte de un animal en situación de calle (entrada del "diario").
///
/// Es un objeto inmutable que sabe convertirse desde/hacia el mapa de SQLite
/// y desde/hacia el JSON de la API web. No conoce la base de datos ni la
/// interfaz (SRP).
class Reporte {
  const Reporte({
    this.id,
    this.idCliente,
    this.servidorId,
    this.albergueId,
    required this.especie,
    required this.estado,
    required this.urgencia,
    required this.descripcion,
    this.cantidadAnimales = 1,
    this.tieneCollar = false,
    this.fechaAvistamiento,
    this.rutaImagen,
    this.rutaAudio,
    required this.latitud,
    required this.longitud,
    required this.fecha,
    this.atendido = false,
  });

  /// Identificador local (SQLite) o, si viene del servidor, el del servidor.
  final int? id;

  /// UUID creado en el teléfono; el servidor lo usa para no duplicar.
  final String? idCliente;

  /// Identificador en MySQL una vez enviado (null = pendiente de enviar).
  final int? servidorId;

  /// Albergue asignado (solo existe en el servidor).
  final int? albergueId;

  final String especie;
  final String estado;

  /// 1 baja, 2 media, 3 alta.
  final int urgencia;
  final String descripcion;

  /// Campo numérico del formulario (1 a 999).
  final int cantidadAnimales;

  /// Campo lógico del formulario.
  final bool tieneCollar;

  /// Campo de fecha del formulario (día en que se vio al animal).
  final DateTime? fechaAvistamiento;

  /// Ruta de la foto en el teléfono, o URL si el reporte viene del servidor.
  final String? rutaImagen;

  /// Ruta de la nota de voz en el teléfono, o URL si viene del servidor.
  final String? rutaAudio;
  final double latitud;
  final double longitud;
  final DateTime fecha;
  final bool atendido;

  bool get sincronizado => servidorId != null;

  Reporte copyWith({bool? atendido, String? idCliente, int? servidorId}) {
    return Reporte(
      id: id,
      idCliente: idCliente ?? this.idCliente,
      servidorId: servidorId ?? this.servidorId,
      albergueId: albergueId,
      especie: especie,
      estado: estado,
      urgencia: urgencia,
      descripcion: descripcion,
      cantidadAnimales: cantidadAnimales,
      tieneCollar: tieneCollar,
      fechaAvistamiento: fechaAvistamiento,
      rutaImagen: rutaImagen,
      rutaAudio: rutaAudio,
      latitud: latitud,
      longitud: longitud,
      fecha: fecha,
      atendido: atendido ?? this.atendido,
    );
  }

  // ------------------------------------------------------------- SQLite

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'id_cliente': idCliente,
      'servidor_id': servidorId,
      'especie': especie,
      'estado': estado,
      'urgencia': urgencia,
      'descripcion': descripcion,
      'cantidad_animales': cantidadAnimales,
      'tiene_collar': tieneCollar ? 1 : 0,
      'fecha_avistamiento': fechaAvistamiento?.millisecondsSinceEpoch,
      'ruta_imagen': rutaImagen,
      'ruta_audio': rutaAudio,
      'latitud': latitud,
      'longitud': longitud,
      'fecha': fecha.millisecondsSinceEpoch,
      'atendido': atendido ? 1 : 0,
    };
  }

  factory Reporte.fromMap(Map<String, Object?> mapa) {
    final avistamiento = mapa['fecha_avistamiento'] as int?;
    return Reporte(
      id: mapa['id'] as int?,
      idCliente: mapa['id_cliente'] as String?,
      servidorId: mapa['servidor_id'] as int?,
      especie: mapa['especie'] as String,
      estado: mapa['estado'] as String,
      urgencia: mapa['urgencia'] as int,
      descripcion: mapa['descripcion'] as String,
      cantidadAnimales: (mapa['cantidad_animales'] as int?) ?? 1,
      tieneCollar: ((mapa['tiene_collar'] as int?) ?? 0) == 1,
      fechaAvistamiento: avistamiento == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(avistamiento),
      rutaImagen: mapa['ruta_imagen'] as String?,
      rutaAudio: mapa['ruta_audio'] as String?,
      latitud: (mapa['latitud'] as num).toDouble(),
      longitud: (mapa['longitud'] as num).toDouble(),
      fecha: DateTime.fromMillisecondsSinceEpoch(mapa['fecha'] as int),
      atendido: (mapa['atendido'] as int) == 1,
    );
  }

  // ----------------------------------------------------------- API web

  /// Cuerpo JSON que se envía en POST /api/reportes.
  Map<String, Object?> toJson() {
    return {
      'id_cliente': idCliente,
      'especie': especie,
      'estado': estado,
      'urgencia': urgencia,
      'descripcion': descripcion,
      'cantidad_animales': cantidadAnimales,
      'tiene_collar': tieneCollar,
      'fecha_avistamiento':
          fechaAvistamiento == null ? null : formatearFechaSola(fechaAvistamiento!),
      'latitud': latitud,
      'longitud': longitud,
      'atendido': atendido,
      'fecha': fecha.toUtc().toIso8601String(),
    };
  }

  /// Convierte un reporte que regresó el servidor. [baseUrl] completa las
  /// rutas relativas de foto y audio (/uploads/...).
  factory Reporte.fromJson(Map<String, dynamic> json, String baseUrl) {
    String? enlace(Object? ruta) => ruta is String ? '$baseUrl$ruta' : null;
    final avistamiento = json['fecha_avistamiento'];
    final idServidor = json['id'] as int;
    return Reporte(
      id: idServidor,
      idCliente: json['id_cliente'] as String?,
      servidorId: idServidor,
      albergueId: json['albergue_id'] as int?,
      especie: json['especie'] as String,
      estado: json['estado'] as String,
      urgencia: json['urgencia'] as int,
      descripcion: json['descripcion'] as String,
      cantidadAnimales: (json['cantidad_animales'] as int?) ?? 1,
      tieneCollar: (json['tiene_collar'] as bool?) ?? false,
      fechaAvistamiento:
          avistamiento is String ? DateTime.tryParse(avistamiento) : null,
      rutaImagen: enlace(json['foto_url']),
      rutaAudio: enlace(json['audio_url']),
      latitud: (json['latitud'] as num).toDouble(),
      longitud: (json['longitud'] as num).toDouble(),
      fecha: DateTime.parse(json['fecha'] as String).toLocal(),
      atendido: (json['atendido'] as bool?) ?? false,
    );
  }
}
