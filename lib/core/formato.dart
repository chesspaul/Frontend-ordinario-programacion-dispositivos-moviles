/// Utilidades de formato (sin dependencias externas).

String _dosDigitos(int n) => n.toString().padLeft(2, '0');

/// dd/mm/aaaa hh:mm
String formatearFecha(DateTime fecha) {
  return '${_dosDigitos(fecha.day)}/${_dosDigitos(fecha.month)}/${fecha.year} '
      '${_dosDigitos(fecha.hour)}:${_dosDigitos(fecha.minute)}';
}

/// mm:ss
String formatearDuracion(Duration duracion) {
  return '${_dosDigitos(duracion.inMinutes)}:'
      '${_dosDigitos(duracion.inSeconds.remainder(60))}';
}

/// aaaa-mm-dd (formato que espera el servidor para fechas sin hora).
String formatearFechaSola(DateTime fecha) {
  return '${fecha.year.toString().padLeft(4, '0')}-'
      '${_dosDigitos(fecha.month)}-${_dosDigitos(fecha.day)}';
}

/// dd/mm/aaaa
String formatearDia(DateTime fecha) {
  return '${_dosDigitos(fecha.day)}/${_dosDigitos(fecha.month)}/${fecha.year}';
}
