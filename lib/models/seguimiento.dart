/// Una nota de seguimiento de un reporte (entidad 3).
class Seguimiento {
  const Seguimiento({
    this.id,
    required this.reporteId,
    required this.fecha,
    required this.nota,
    this.estadoNuevo,
    this.requiereTraslado = false,
  });

  final int? id;
  final int reporteId;
  final DateTime fecha;
  final String nota;

  /// Si viene, el servidor también actualiza el estado del reporte.
  final String? estadoNuevo;
  final bool requiereTraslado;

  factory Seguimiento.fromJson(Map<String, dynamic> json) {
    return Seguimiento(
      id: json['id'] as int,
      reporteId: json['reporte_id'] as int,
      fecha: DateTime.parse(json['fecha'] as String),
      nota: json['nota'] as String,
      estadoNuevo: json['estado_nuevo'] as String?,
      requiereTraslado: (json['requiere_traslado'] as bool?) ?? false,
    );
  }
}
