import 'dart:math';

final Random _azar = Random.secure();

/// Genera un UUID v4 (identificador único universal) sin paquetes externos.
///
/// Se usa como `id_cliente`: la app lo crea al guardar el reporte y el
/// servidor lo usa para no duplicar si el envío se reintenta.
String generarUuid() {
  final bytes = List<int>.generate(16, (_) => _azar.nextInt(256));
  bytes[6] = (bytes[6] & 0x0F) | 0x40; // versión 4
  bytes[8] = (bytes[8] & 0x3F) | 0x80; // variante RFC 4122
  String hex(int desde, int hasta) => bytes
      .sublist(desde, hasta)
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
}
