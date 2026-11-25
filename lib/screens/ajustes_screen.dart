import 'package:flutter/material.dart';

import '../app/inyector.dart';
import '../core/app_exception.dart';
import '../services/ajustes_service.dart';

/// Ajustes: dirección del servidor (se guarda en un archivo plano).
class AjustesScreen extends StatefulWidget {
  const AjustesScreen({super.key});

  @override
  State<AjustesScreen> createState() => _AjustesScreenState();
}

class _AjustesScreenState extends State<AjustesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlCtrl = TextEditingController();

  bool _cargando = true;
  bool _probando = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final url = await Inyector.ajustes.leerUrlServidor();
    if (!mounted) return;
    setState(() {
      _urlCtrl.text = url;
      _cargando = false;
    });
  }

  void _aviso(String mensaje) {
    if (!mounted) return;
    final mensajero = ScaffoldMessenger.of(context);
    mensajero.hideCurrentSnackBar();
    mensajero.showSnackBar(SnackBar(content: Text(mensaje)));
  }

  String? _validarUrl(String? valor) {
    final texto = AjustesService.normalizar(valor ?? '');
    final uri = Uri.tryParse(texto);
    final valida = uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
    return valida ? null : 'Escribe una dirección como http://localhost:3000';
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await Inyector.ajustes.guardarUrlServidor(_urlCtrl.text);
      _aviso('Dirección guardada.');
    } catch (e) {
      _aviso(mensajeDeError(e));
    }
  }

  Future<void> _probar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _probando = true);
    try {
      await Inyector.apiRepository
          .probarConexion(AjustesService.normalizar(_urlCtrl.text));
      _aviso('Conexión correcta: el servidor y MySQL responden.');
    } catch (e) {
      _aviso(mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _probando = false);
    }
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('Servidor', style: textos.titleMedium),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _urlCtrl,
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'Dirección de la API',
                      prefixIcon: Icon(Icons.dns_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: _validarUrl,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _probando ? null : _probar,
                          icon: _probando
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.wifi_tethering),
                          label: const Text('Probar conexión'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _guardar,
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Guardar'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('¿Qué dirección uso?', style: textos.titleMedium),
                  const SizedBox(height: 8),
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• Celular por USB: http://localhost:3000\n'
                              '  (antes ejecuta: adb reverse tcp:3000 tcp:3000)'),
                          SizedBox(height: 8),
                          Text('• Emulador Android: http://10.0.2.2:3000'),
                          SizedBox(height: 8),
                          Text('• Misma red Wi-Fi: http://IP-DE-LA-PC:3000'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
