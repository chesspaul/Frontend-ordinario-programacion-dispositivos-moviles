/// Un albergue o refugio al que se canalizan los reportes (entidad 2).
class Albergue {
  const Albergue({
    this.id,
    required this.nombre,
    required this.telefono,
    required this.zona,
    this.totalReportes = 0,
  });

  final int? id;
  final String nombre;

  /// 10 dígitos.
  final String telefono;
  final String zona;

  /// Cuántos reportes tiene asignados (lo calcula el servidor).
  final int totalReportes;

  Map<String, Object?> toJson() => {
        'nombre': nombre,
        'telefono': telefono,
        'zona': zona,
      };

  factory Albergue.fromJson(Map<String, dynamic> json) {
    return Albergue(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      telefono: json['telefono'] as String,
      zona: json['zona'] as String,
      totalReportes: (json['total_reportes'] as int?) ?? 0,
    );
  }
}
