import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/movimiento_caja.dart';
import '../services/database_helper.dart';

class CajaScreen extends StatefulWidget {
  const CajaScreen({super.key});

  @override
  State<CajaScreen> createState() => _CajaScreenState();
}

class _CajaScreenState extends State<CajaScreen> {
  final _dbHelper = DatabaseHelper.instance;
  List<MovimientoCaja> _movimientos = [];
  bool _isLoading = true;
  DateTime _fechaSeleccionada = DateTime.now();
  double _totalVentas = 0;
  double _totalIngresos = 0;
  double _totalEgresos = 0;
  double _saldoCaja = 0;
  double? _fondoInicial;

  @override
  void initState() {
    super.initState();
    _cargarMovimientos();
  }

  Future<void> _cargarMovimientos() async {
    setState(() => _isLoading = true);
    
    final movimientos = await _dbHelper.getMovimientosPorFecha(_fechaSeleccionada);
    final ventas = await _dbHelper.getTotalVentasDia(_fechaSeleccionada);
    final ingresos = await _dbHelper.getTotalIngresosDia(_fechaSeleccionada);
    final egresos = await _dbHelper.getTotalEgresosDia(_fechaSeleccionada);
    final fondo = await _dbHelper.obtenerFondoDelDia(_fechaSeleccionada);
    
    setState(() {
      _movimientos = movimientos;
      _totalVentas = ventas;
      _totalIngresos = ingresos;
      _totalEgresos = egresos;
      _fondoInicial = fondo;
      _saldoCaja = (fondo ?? 0) + ventas + ingresos - egresos;
      _isLoading = false;
    });
  }

  void _mostrarDialogoFondo() {
    final controller = TextEditingController(
      text: _fondoInicial?.toStringAsFixed(2) ?? '',
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.account_balance_wallet, color: Colors.blue),
            ),
            const SizedBox(width: 12),
            Text(_fondoInicial == null ? 'Agregar Fondo del Día' : 'Editar Fondo del Día'),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Monto del fondo inicial',
            prefixText: '\$ ',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final monto = double.tryParse(controller.text);
              if (monto == null || monto <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ingrese un monto válido')),
                );
                return;
              }
              
              if (_fondoInicial == null) {
                await _dbHelper.guardarFondoDelDia(_fechaSeleccionada, monto);
              } else {
                await _dbHelper.actualizarFondoDelDia(_fechaSeleccionada, monto);
              }

              if (!context.mounted) return;
              Navigator.pop(context);
              _cargarMovimientos();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: Text(_fondoInicial == null ? 'Guardar' : 'Actualizar'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoMovimiento(String tipo) {
    showDialog(
      context: context,
      builder: (context) => NuevoMovimientoDialog(
        tipo: tipo,
        onGuardado: _cargarMovimientos,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatoCurrency = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    final formatoFecha = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Caja', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          if (_fondoInicial == null)
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 160),
                    child: const Text(
                      'Ingresa el fondo de hoy',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_right_alt, size: 18, color: Colors.black54),
                  IconButton(
                    icon: const Icon(Icons.account_balance_wallet),
                    onPressed: _mostrarDialogoFondo,
                    tooltip: 'Agregar fondo del día',
                  ),
                ],
              ),
            ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final fecha = await showDatePicker(
                context: context,
                initialDate: _fechaSeleccionada,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (fecha != null) {
                setState(() => _fechaSeleccionada = fecha);
                _cargarMovimientos();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        formatoFecha.format(_fechaSeleccionada),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Saldo Total
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.deepPurple, Colors.deepPurple[300]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepPurple.withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                _buildSaldoActionButton(
                                  label: '+Ingreso',
                                  icon: Icons.add,
                                  onPressed: () => _mostrarDialogoMovimiento('ingreso'),
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Saldo en Caja',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildSaldoActionButton(
                                  label: '-Egreso',
                                  icon: Icons.remove,
                                  onPressed: () => _mostrarDialogoMovimiento('egreso'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              formatoCurrency.format(_saldoCaja),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Fondo inicial si existe
                      if (_fondoInicial != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.account_balance_wallet, color: Colors.blue[700], size: 20),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Fondo Inicial',
                                    style: TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(
                                    formatoCurrency.format(_fondoInicial),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 18),
                                    onPressed: _mostrarDialogoFondo,
                                    color: Colors.blue[700],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      // Resumen
                      Row(
                        children: [
                          Expanded(
                            child: _buildResumenCard(
                              'Ventas',
                              _totalVentas,
                              Colors.green,
                              Icons.point_of_sale,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildResumenCard(
                              'Ingresos',
                              _totalIngresos,
                              Colors.blue,
                              Icons.arrow_downward,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildResumenCard(
                              'Egresos',
                              _totalEgresos,
                              Colors.red,
                              Icons.arrow_upward,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      const Text(
                        'Movimientos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_movimientos.length} registros',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _movimientos.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long_outlined,
                                  size: 80, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text(
                                'No hay movimientos',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _movimientos.length,
                          itemBuilder: (context, index) {
                            final mov = _movimientos[index];
                            return _buildMovimientoCard(mov);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildSaldoActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 32,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.2),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildResumenCard(String titulo, double monto, Color color, IconData icono) {
    final formatoCurrency = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icono, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            titulo,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatoCurrency.format(monto),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMovimientoCard(MovimientoCaja mov) {
    final formatoCurrency = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    final formatoHora = DateFormat('HH:mm');
    
    Color color;
    IconData icono;
    
    switch (mov.tipo) {
      case 'venta':
        color = Colors.green;
        icono = Icons.point_of_sale;
        break;
      case 'ingreso':
        color = Colors.blue;
        icono = Icons.arrow_downward;
        break;
      case 'egreso':
        color = Colors.red;
        icono = Icons.arrow_upward;
        break;
      default:
        color = Colors.grey;
        icono = Icons.help;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icono, color: color, size: 24),
        ),
        title: Text(
          mov.concepto ?? mov.tipo.toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (mov.notas != null && mov.notas!.isNotEmpty)
              Text(
                mov.notas!,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            Text(
              formatoHora.format(mov.fecha),
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
        trailing: Text(
          formatoCurrency.format(mov.monto),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}

class NuevoMovimientoDialog extends StatefulWidget {
  final String tipo;
  final VoidCallback onGuardado;

  const NuevoMovimientoDialog({
    super.key,
    required this.tipo,
    required this.onGuardado,
  });

  @override
  State<NuevoMovimientoDialog> createState() => _NuevoMovimientoDialogState();
}

class _NuevoMovimientoDialogState extends State<NuevoMovimientoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  final _conceptoController = TextEditingController();
  final _notasController = TextEditingController();
  final _dbHelper = DatabaseHelper.instance;

  @override
  void dispose() {
    _montoController.dispose();
    _conceptoController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final movimiento = MovimientoCaja(
      tipo: widget.tipo,
      monto: double.parse(_montoController.text),
      concepto: _conceptoController.text.isEmpty ? null : _conceptoController.text,
      notas: _notasController.text.isEmpty ? null : _notasController.text,
    );

    await _dbHelper.insertMovimientoCaja(movimiento);
    widget.onGuardado();
    
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.tipo == 'ingreso' ? Colors.green : Colors.red;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.tipo == 'ingreso' ? Icons.add : Icons.remove,
                      color: color,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    widget.tipo == 'ingreso' ? 'Nuevo Ingreso' : 'Nuevo Egreso',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _montoController,
                decoration: InputDecoration(
                  labelText: 'Monto *',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El monto es requerido';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Ingrese un monto válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _conceptoController,
                decoration: InputDecoration(
                  labelText: 'Concepto',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notasController,
                decoration: InputDecoration(
                  labelText: 'Notas',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Guardar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
