# Patitas en la calle (app Flutter)

Aplicación móvil para reportar animales en situación de calle, con comunicación web.
Proyecto ordinario de Programación de dispositivos móviles (Universidad Anáhuac).

- Autor: Paul Iván Rosales Campos 


## Qué hace

- Registra reportes con foto, nota de voz, dictado por voz, ubicación GPS, cantidad de animales, collar (sí/no) y fecha de avistamiento.
- Guarda los reportes en el teléfono (SQLite) y los envía a la API, que los registra en MySQL. Si no hay conexión, quedan pendientes y se reenvían después sin duplicarse (cada reporte lleva un UUID).
- Consulta los reportes del servidor con filtros, y permite marcarlos como atendidos o eliminarlos.
- Administra albergues (cuadrícula) y el seguimiento de cada reporte (bitácora y asignación de albergue).
- Guarda la dirección del servidor en un archivo plano (`ajustes.json`).

## Requisitos del proyecto y dónde están

| Requisito | Dónde |
|---|---|
| Imágenes | `widgets/foto_reporte.dart`, `widgets/reporte_card.dart` |
| Widgets con scroll | `ListView` en `lista_screen` y `servidor_screen`, `GridView` en `albergues_screen` |
| Navegación | `app/rutas.dart` (9 rutas con nombre), `widgets/app_drawer.dart` |
| Paso de información entre pantallas | `pushNamed` con `arguments` (Reporte, Albergue) y `pop(context, true)` |
| Formularios (texto, numérico, lógico, fecha) | `formulario_screen`, `albergue_form_screen`, `seguimientos_screen` |
| Gadgets | cámara y galería, micrófono, dictado por voz y GPS (`services/`) |
| Almacenamiento físico | SQLite (`data/database_helper.dart`) y archivo plano (`services/ajustes_service.dart`) |
| Servicios web | `services/api_client.dart`, `data/api_*_repository.dart` |

## Estructura de `lib/`

```
app/        rutas, tema e inyector de dependencias
core/       excepciones, formato y generador de UUID
data/       repositorios (SQLite y API) y DatabaseHelper
models/     Reporte, Albergue, Seguimiento y catálogos
screens/    pantallas
services/   ApiClient, sincronizador, ajustes, cámara, audio, voz, GPS
widgets/    tarjetas, foto, mapa, reproductor, menú lateral
```

## Cómo ejecutarla

1. Levanta primero el backend (ver su README): MySQL con `schema.sql`, `npm install` y `npm start`. La API queda en el puerto 3000.
2. Instala dependencias de la app:
   ```
   flutter pub get
   ```
3. Conecta un teléfono Android con depuración USB y ejecuta:
   ```
   flutter run
   ```
4. Indica la dirección del servidor en **Menú → Ajustes** y toca **Probar conexión**:
    - Teléfono por USB: ejecuta `adb reverse tcp:3000 tcp:3000` y usa `http://localhost:3000`.
    - Emulador de Android: `http://10.0.2.2:3000`.
    - Por Wi-Fi: `http://IP-DE-LA-COMPUTADORA:3000` (misma red, y el puerto 3000 permitido en el firewall).

El `AndroidManifest.xml` incluye `usesCleartextTraffic` para permitir HTTP en desarrollo.

## Versiones

Flutter 3.47.2 · Dart 3.13.2 · probada en Honor X8b (Android 14).