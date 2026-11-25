import '../data/api_albergue_repository.dart';
import '../data/api_reporte_repository.dart';
import '../data/api_seguimiento_repository.dart';
import '../data/database_helper.dart';
import '../data/reporte_repository.dart';
import '../data/sqlite_reporte_repository.dart';
import '../services/ajustes_service.dart';
import '../services/api_client.dart';
import '../services/archivo_service.dart';
import '../services/audio_service.dart';
import '../services/image_service.dart';
import '../services/location_service.dart';
import '../services/maps_launcher.dart';
import '../services/sincronizador_service.dart';
import '../services/speech_service.dart';

/// Punto único donde se construyen las dependencias (inversión de
/// dependencias): las pantallas piden abstracciones/servicios aquí y no
/// crean sus propias implementaciones concretas.
class Inyector {
  Inyector._();

  static final ArchivoService archivoService = ArchivoService();

  static final SqliteReporteRepository sqliteRepository =
      SqliteReporteRepository(DatabaseHelper.instance);

  /// La UI depende de la abstracción [ReporteRepository], no de SQLite.
  static final ReporteRepository reporteRepository = sqliteRepository;

  // ----------------------------------------------- Comunicación web (API)

  /// Ajustes en archivo plano (dirección del servidor).
  static final AjustesService ajustes = AjustesService();
  static final ApiClient apiClient = ApiClient(ajustes);

  /// Misma abstracción, otra fuente de datos: MySQL vía API REST.
  static final ApiReporteRepository apiRepository =
      ApiReporteRepository(apiClient);

  static final ApiAlbergueRepository albergueRepository =
      ApiAlbergueRepository(apiClient);
  static final ApiSeguimientoRepository seguimientoRepository =
      ApiSeguimientoRepository(apiClient);

  /// Envía a MySQL lo guardado en SQLite.
  static final SincronizadorService sincronizador =
      SincronizadorService(sqliteRepository, apiRepository);

  static final ImageService imageService = ImageService(archivoService);
  static final LocationService locationService = LocationService();
  static final MapsLauncher mapsLauncher = MapsLauncher();

  /// El micrófono es un recurso exclusivo: cada pantalla crea el suyo.
  static AudioService crearAudioService() => AudioService(archivoService);

  static SpeechService crearSpeechService() => SpeechService();
}
