import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/image_saver_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';
import '../models/movimiento_caja.dart';
import '../services/database_helper.dart';
import '../services/user_profile_service.dart';

class CorteDiaScreen extends StatefulWidget {
  const CorteDiaScreen({super.key});

  @override
  State<CorteDiaScreen> createState() => _CorteDiaScreenState();
}

class _CorteDiaScreenState extends State<CorteDiaScreen> {
  final _dbHelper = DatabaseHelper.instance;
  final _montoRealController = TextEditingController();
  final _notasController = TextEditingController();
  final ScreenshotController _screenshotController = ScreenshotController();
  
  final DateTime _fecha = DateTime.now();
  bool _isLoading = true;
  double _totalVentas = 0;
  double _totalIngresos = 0;
  double _totalEgresos = 0;
  double _totalDevoluciones = 0;
  double _montoEsperado = 0;
  CorteDia? _corteExistente;
  UserProfileService? _profileService;
  String? _userName;
  String? _businessName;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _cargarPerfil();
  }
  
  Future<void> _cargarPerfil() async {
    _profileService = await UserProfileService.getInstance();
    setState(() {
      _userName = _profileService!.getUserName();
      _businessName = _profileService!.getBusinessName();
    });
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    
    final ventas = await _dbHelper.getTotalVentasDia(_fecha);
    final ingresos = await _dbHelper.getTotalIngresosDia(_fecha);
    final egresos = await _dbHelper.getTotalEgresosDia(_fecha);
    final devoluciones = await _dbHelper.getTotalDevolucionesDia(_fecha);
    final corte = await _dbHelper.getCortePorFecha(_fecha);
    
    setState(() {
      _totalVentas = ventas;
      _totalIngresos = ingresos;
      _totalEgresos = egresos;
      _totalDevoluciones = devoluciones;
      _corteExistente = corte;
      _isLoading = false;
      
      if (corte != null) {
        _montoRealController.text = corte.montoReal.toString();
        _notasController.text = corte.notas ?? '';
        _montoEsperado = corte.montoEsperado;
      }
    });
  }

  Future<void> _guardarCorte() async {
    final montoReal = double.tryParse(_montoRealController.text) ?? 0;
    final montoEsperado = _totalVentas + _totalIngresos - _totalEgresos;
    final diferencia = montoReal - montoEsperado;

    final corte = CorteDia(
      fecha: _fecha,
      montoInicial: 0,
      totalVentas: _totalVentas,
      totalIngresos: _totalIngresos,
      totalEgresos: _totalEgresos,
      montoEsperado: montoEsperado,
      montoReal: montoReal,
      diferencia: diferencia,
      notas: _notasController.text.isEmpty ? null : _notasController.text,
    );

    await _dbHelper.insertCorteDia(corte);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Corte guardado exitosamente'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Descargar',
            textColor: Colors.white,
            onPressed: _exportarCorte,
          ),
        ),
      );
      _cargarDatos();
    }
  }
  
  Future<bool> _solicitarPermisoGuardar() async {
    if (Platform.isIOS) {
      final status = await Permission.photosAddOnly.request();
      return status.isGranted;
    }
    if (Platform.isAndroid) {
      final photos = await Permission.photos.request();
      if (photos.isGranted) return true;
      final storage = await Permission.storage.request();
      return storage.isGranted;
    }
    return true;
  }

  Future<void> _exportarCorte() async {
    try {
      final permitido = await _solicitarPermisoGuardar();
      if (!permitido) {
        throw Exception('Permiso denegado para guardar imagen');
      }

      final image = await _screenshotController.captureFromWidget(
        _buildCorteContenido(
          NumberFormat.currency(locale: 'es_MX', symbol: '\$'),
          double.tryParse(_montoRealController.text) ?? 0,
          _getAnalisisTecnico(),
        ),
        pixelRatio: 2.0,
      );

      final nombre = 'corte_${DateFormat('yyyyMMdd_HHmmss').format(_fecha)}';
      final result = await ImageSaverService.saveImage(
        image,
        quality: 100,
        name: nombre,
      );
      final success = result['isSuccess'] == true || result['isSuccess'] == 1;
      if (!success) {
        throw Exception('No se pudo guardar la imagen');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Imagen guardada en la galeria'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  String _getAnalisisTecnico() {
    final montoReal = double.tryParse(_montoRealController.text) ?? 0;
    final diferencia = montoReal - _montoEsperado;
    final porcentajeDiferencia = _montoEsperado != 0 
        ? (diferencia / _montoEsperado * 100).abs() 
        : 0;
    
    if (diferencia == 0) {
      return 'Corte exacto. Excelente manejo de caja.';
    } else if (diferencia > 0) {
      if (porcentajeDiferencia < 1) {
        return 'Sobrante menor al 1%. Diferencia aceptable.';
      } else if (porcentajeDiferencia < 5) {
        return 'Sobrante moderado. Revisar procedimientos.';
      } else {
        return 'Sobrante significativo. Verificar registro de ventas.';
      }
    } else {
      if (porcentajeDiferencia < 1) {
        return 'Faltante menor al 1%. Diferencia aceptable.';
      } else if (porcentajeDiferencia < 5) {
        return 'Faltante moderado. Revisar devoluciones y gastos.';
      } else {
        return 'Faltante significativo. Auditoría recomendada.';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatoCurrency = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    final montoReal = double.tryParse(_montoRealController.text) ?? 0;
    _montoEsperado = _totalVentas + _totalIngresos - _totalEgresos;
    final analisisTecnico = _getAnalisisTecnico();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Corte del Día',
            style: TextStyle(fontWeight: FontWeight.w600)),
        elevation: 0,
        actions: [
          if (_corteExistente != null)
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Exportar como imagen',
              onPressed: _exportarCorte,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Contenido que se capturará en screenshot
                  Screenshot(
                    controller: _screenshotController,
                    child: _buildCorteContenido(
                      formatoCurrency,
                      montoReal,
                      analisisTecnico,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CortesSemanaScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.history),
                            label: const Text('Ver Cortes Anteriores'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        if (_corteExistente != null) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _exportarCorte,
                              icon: const Icon(Icons.download),
                              label: const Text('Descargar Imagen'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Formulario de entrada (no se captura)
                  if (_corteExistente == null)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Realizar Corte',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                TextFormField(
                                  controller: _montoRealController,
                                  decoration: InputDecoration(
                                    labelText: 'Dinero en caja',
                                    prefixText: '\$ ',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                  ],
                                  onChanged: (value) => setState(() {}),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _notasController,
                                  decoration: InputDecoration(
                                    labelText: 'Notas (opcional)',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                  ),
                                  maxLines: 3,
                                  onChanged: (value) => setState(() {}),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          ElevatedButton.icon(
                            onPressed: _guardarCorte,
                            icon: const Icon(Icons.save),
                            label: const Text('Guardar Corte'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildResumenRow(String label, double monto, Color color) {
    final formatoCurrency = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        Text(
          formatoCurrency.format(monto),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
  
  Widget _buildDetalleRow(String label, double monto) {
    final formatoCurrency = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          Text(
            formatoCurrency.format(monto),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorteContenido(
    NumberFormat formatoCurrency,
    double montoReal,
    String analisisTecnico,
  ) {
    final diferencia = montoReal - _montoEsperado;
    return MediaQuery(
      data: const MediaQueryData(),
      child: Material(
        color: Colors.white,
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(20),
          child: DefaultTextStyle(
            style: const TextStyle(
              color: Colors.black87,
              fontFamily: 'Roboto',
              fontSize: 14,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.deepPurple, Colors.deepPurple[300]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Image.asset(
                          'assets/images/TiendaDeAbarrotesd.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _businessName ?? 'Tienda de Abarrotes',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'CORTE DE CAJA',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_today, color: Colors.white, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('dd/MM/yyyy').format(_fecha),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_userName != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.person, color: Colors.white70, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Encargado: $_userName',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Resumen del Dia',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildResumenRow('Ventas', _totalVentas, Colors.green),
                      const SizedBox(height: 12),
                      _buildResumenRow('Ingresos', _totalIngresos, Colors.blue),
                      const SizedBox(height: 12),
                      _buildResumenRow('Egresos', _totalEgresos, Colors.red),
                      if (_totalDevoluciones > 0) ...[
                        const SizedBox(height: 12),
                        _buildResumenRow('Devoluciones', _totalDevoluciones, Colors.orange),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detalles del Corte',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDetalleRow('Monto Esperado', _montoEsperado),
                      _buildDetalleRow('Dinero en caja', montoReal),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            diferencia >= 0 ? 'Sobrante' : 'Faltante',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            formatoCurrency.format(diferencia.abs()),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: diferencia >= 0 ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.analytics, color: Colors.orange[700], size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Analisis Tecnico',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[900],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              analisisTecnico,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.orange[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_notasController.text.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.note, color: Colors.blue[700], size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Notas',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[900],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _notasController.text,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    'Generado: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _montoRealController.dispose();
    _notasController.dispose();
    super.dispose();
  }
}

class CortesSemanaScreen extends StatefulWidget {
  const CortesSemanaScreen({super.key});

  @override
  State<CortesSemanaScreen> createState() => _CortesSemanaScreenState();
}

class _CortesSemanaScreenState extends State<CortesSemanaScreen> {
  final _dbHelper = DatabaseHelper.instance;
  final ScreenshotController _screenshotController = ScreenshotController();
  List<CorteDia> _cortes = [];
  bool _isLoading = true;
  int _paginaActual = 0;
  static const int _tamanoPagina = 7;
  String? _businessName;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _cargarCortes();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    final profileService = await UserProfileService.getInstance();
    setState(() {
      _userName = profileService.getUserName();
      _businessName = profileService.getBusinessName();
    });
  }

  Future<void> _cargarCortes() async {
    setState(() => _isLoading = true);
    final cortes = await _dbHelper.getAllCortes();
    final inicioSemana = DateTime.now().subtract(const Duration(days: 6));
    final filtrados = cortes.where((c) => c.fecha.isAfter(
      DateTime(inicioSemana.year, inicioSemana.month, inicioSemana.day).subtract(const Duration(seconds: 1)),
    )).toList();
    filtrados.sort((a, b) => b.fecha.compareTo(a.fecha));
    setState(() {
      _cortes = filtrados;
      _paginaActual = 0;
      _isLoading = false;
    });
  }

  List<CorteDia> _cortesPaginados() {
    if (_cortes.isEmpty) return [];
    final totalPaginas = (_cortes.length / _tamanoPagina).ceil();
    final pagina = _paginaActual.clamp(0, totalPaginas - 1);
    final inicio = pagina * _tamanoPagina;
    final fin = (inicio + _tamanoPagina) > _cortes.length
        ? _cortes.length
        : (inicio + _tamanoPagina);
    return _cortes.sublist(inicio, fin);
  }

  Future<void> _eliminarCorte(CorteDia corte) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar corte'),
        content: const Text('Esta accion no se puede deshacer. Desea continuar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      await _dbHelper.deleteCorteDia(corte.id!);
      _cargarCortes();
    }
  }

  Future<void> _descargarCorte(CorteDia corte) async {
    try {
      final formatoCurrency = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
      final diferencia = corte.montoReal - corte.montoEsperado;

      final image = await _screenshotController.captureFromWidget(
        _buildCorteImagenAnterior(corte, formatoCurrency, diferencia),
        pixelRatio: 2.0,
      );

      final nombre = 'corte_${DateFormat('yyyyMMdd').format(corte.fecha)}';
      final result = await ImageSaverService.saveImage(
        image,
        quality: 100,
        name: nombre,
      );
      final success = result['isSuccess'] == true || result['isSuccess'] == 1;
      if (!success) {
        throw Exception('No se pudo guardar la imagen');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Corte del ${DateFormat('dd/MM/yyyy').format(corte.fecha)} guardado en galería'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al descargar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildCorteImagenAnterior(CorteDia corte, NumberFormat fmt, double diferencia) {
    return MediaQuery(
      data: const MediaQueryData(),
      child: Material(
        color: Colors.white,
        child: Container(
          width: 400,
          color: Colors.white,
          padding: const EdgeInsets.all(20),
          child: DefaultTextStyle(
            style: const TextStyle(color: Colors.black87, fontFamily: 'Roboto', fontSize: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.deepPurple, Colors.deepPurple[300]!],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _businessName ?? 'Tienda de Abarrotes',
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text('CORTE DE CAJA', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14, letterSpacing: 2)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                        child: Text(DateFormat('dd/MM/yyyy').format(corte.fecha), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                      if (_userName != null) ...[
                        const SizedBox(height: 8),
                        Text('Encargado: $_userName', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Resumen', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 12),
                      _buildFilaResumenImg('Ventas', corte.totalVentas, Colors.green, fmt),
                      const SizedBox(height: 8),
                      _buildFilaResumenImg('Ingresos', corte.totalIngresos, Colors.blue, fmt),
                      const SizedBox(height: 8),
                      _buildFilaResumenImg('Egresos', corte.totalEgresos, Colors.red, fmt),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)),
                  child: Column(
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text('Esperado', style: TextStyle(fontWeight: FontWeight.w500)),
                        Text(fmt.format(corte.montoEsperado), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ]),
                      const SizedBox(height: 8),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text('En caja', style: TextStyle(fontWeight: FontWeight.w500)),
                        Text(fmt.format(corte.montoReal), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ]),
                      const Divider(height: 20),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(diferencia >= 0 ? 'Sobrante' : 'Faltante', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(fmt.format(diferencia.abs()), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: diferencia >= 0 ? Colors.green : Colors.red)),
                      ]),
                    ],
                  ),
                ),
                if (corte.notas != null && corte.notas!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Icon(Icons.note, color: Colors.blue[700], size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(corte.notas!, style: TextStyle(fontSize: 13, color: Colors.blue[800]))),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Center(child: Text('Generado: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}', style: TextStyle(fontSize: 11, color: Colors.grey[600]))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilaResumenImg(String label, double monto, Color color, NumberFormat fmt) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ]),
        Text(fmt.format(monto), style: TextStyle(fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatoCurrency = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    final cortesPagina = _cortesPaginados();
    final totalPaginas = _cortes.isEmpty ? 0 : (_cortes.length / _tamanoPagina).ceil();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cortes de la Semana', style: TextStyle(fontWeight: FontWeight.w600)),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _cortes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text('No hay cortes en la semana', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: cortesPagina.length,
                          itemBuilder: (context, index) {
                            final corte = cortesPagina[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                title: Text(
                                  DateFormat('dd/MM/yyyy').format(corte.fecha),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 6),
                                    Text('Ventas: ${formatoCurrency.format(corte.totalVentas)}'),
                                    Text('Ingresos: ${formatoCurrency.format(corte.totalIngresos)}'),
                                    Text('Egresos: ${formatoCurrency.format(corte.totalEgresos)}'),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.download, color: Colors.deepPurple),
                                      tooltip: 'Descargar imagen',
                                      onPressed: () => _descargarCorte(corte),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      onPressed: () => _eliminarCorte(corte),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                if (totalPaginas > 1)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: _paginaActual > 0
                              ? () => setState(() => _paginaActual -= 1)
                              : null,
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Text(
                          'Pagina ${_paginaActual + 1} de $totalPaginas',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        IconButton(
                          onPressed: (_paginaActual + 1) < totalPaginas
                              ? () => setState(() => _paginaActual += 1)
                              : null,
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
