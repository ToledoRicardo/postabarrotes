import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/venta.dart';
import '../services/database_helper.dart';

class HistorialVentasScreen extends StatefulWidget {
  const HistorialVentasScreen({super.key});

  @override
  State<HistorialVentasScreen> createState() => _HistorialVentasScreenState();
}

class _HistorialVentasScreenState extends State<HistorialVentasScreen> {
  final _dbHelper = DatabaseHelper.instance;
  List<Venta> _ventas = [];
  bool _isLoading = true;
  int _paginaActual = 0;
  static const int _tamanoPagina = 5;

  // Filtros
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;
  String _ordenSeleccionado = 'reciente'; // reciente, antiguo, mayor, menor

  @override
  void initState() {
    super.initState();
    _cargarVentas();
  }

  Future<void> _cargarVentas() async {
    setState(() => _isLoading = true);
    final ventas = await _dbHelper.getAllVentas();
    setState(() {
      _ventas = ventas;
      _paginaActual = 0;
      _isLoading = false;
    });
  }

  List<Venta> get _ventasFiltradas {
    var filtradas = List<Venta>.from(_ventas);

    // Filtro por fecha
    if (_fechaDesde != null) {
      final desde = DateTime(_fechaDesde!.year, _fechaDesde!.month, _fechaDesde!.day);
      filtradas = filtradas.where((v) => !v.fechaVenta.isBefore(desde)).toList();
    }
    if (_fechaHasta != null) {
      final hasta = DateTime(_fechaHasta!.year, _fechaHasta!.month, _fechaHasta!.day)
          .add(const Duration(days: 1));
      filtradas = filtradas.where((v) => v.fechaVenta.isBefore(hasta)).toList();
    }

    // Ordenar
    switch (_ordenSeleccionado) {
      case 'reciente':
        filtradas.sort((a, b) => b.fechaVenta.compareTo(a.fechaVenta));
        break;
      case 'antiguo':
        filtradas.sort((a, b) => a.fechaVenta.compareTo(b.fechaVenta));
        break;
      case 'mayor':
        filtradas.sort((a, b) => b.total.compareTo(a.total));
        break;
      case 'menor':
        filtradas.sort((a, b) => a.total.compareTo(b.total));
        break;
    }

    return filtradas;
  }

  Future<void> _eliminarVenta(int ventaId) async {
    await _dbHelper.deleteVenta(ventaId);
    _cargarVentas();
  }

  void _mostrarDialogoEliminar(Venta venta) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar venta'),
        content: Text('¿Eliminar la venta #${venta.id}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _eliminarVenta(venta.id!);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _seleccionarFecha(bool esDesde) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: esDesde
          ? (_fechaDesde ?? DateTime.now())
          : (_fechaHasta ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (fecha != null) {
      setState(() {
        if (esDesde) {
          _fechaDesde = fecha;
        } else {
          _fechaHasta = fecha;
        }
        _paginaActual = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatoCurrency = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    final formatoFecha = DateFormat('dd/MM/yyyy HH:mm');
    final formatoFechaCorta = DateFormat('dd/MM/yy');
    final ventasFiltradas = _ventasFiltradas;
    final totalPaginas = ventasFiltradas.isEmpty
        ? 1
        : (ventasFiltradas.length / _tamanoPagina).ceil();
    if (_paginaActual >= totalPaginas) _paginaActual = totalPaginas - 1;
    final inicio = _paginaActual * _tamanoPagina;
    final fin = (inicio + _tamanoPagina) > ventasFiltradas.length
        ? ventasFiltradas.length
        : inicio + _tamanoPagina;
    final ventasPagina = ventasFiltradas.isEmpty
        ? <Venta>[]
        : ventasFiltradas.sublist(inicio, fin);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Ventas',
            style: TextStyle(fontWeight: FontWeight.w600)),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filtros
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Column(
                    children: [
                      // Filtro por fecha
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _seleccionarFecha(true),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today,
                                        size: 16, color: Colors.grey[600]),
                                    const SizedBox(width: 6),
                                    Text(
                                      _fechaDesde != null
                                          ? formatoFechaCorta
                                              .format(_fechaDesde!)
                                          : 'Desde',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: _fechaDesde != null
                                            ? null
                                            : Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: InkWell(
                              onTap: () => _seleccionarFecha(false),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today,
                                        size: 16, color: Colors.grey[600]),
                                    const SizedBox(width: 6),
                                    Text(
                                      _fechaHasta != null
                                          ? formatoFechaCorta
                                              .format(_fechaHasta!)
                                          : 'Hasta',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: _fechaHasta != null
                                            ? null
                                            : Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (_fechaDesde != null || _fechaHasta != null)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                setState(() {
                                  _fechaDesde = null;
                                  _fechaHasta = null;
                                  _paginaActual = 0;
                                });
                              },
                              tooltip: 'Limpiar fechas',
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Ordenar
                      Row(
                        children: [
                          const Icon(Icons.sort, size: 18),
                          const SizedBox(width: 6),
                          const Text('Ordenar:', style: TextStyle(fontSize: 13)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildChipOrden('Reciente', 'reciente'),
                                  const SizedBox(width: 4),
                                  _buildChipOrden('Antiguo', 'antiguo'),
                                  const SizedBox(width: 4),
                                  _buildChipOrden('Mayor \$', 'mayor'),
                                  const SizedBox(width: 4),
                                  _buildChipOrden('Menor \$', 'menor'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Lista
                Expanded(
                  child: ventasFiltradas.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long_outlined,
                                  size: 80, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text(
                                'No hay ventas registradas',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: ventasPagina.length,
                          itemBuilder: (context, index) {
                            final venta = ventasPagina[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2,
                              child: ExpansionTile(
                                tilePadding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 8),
                                leading: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.green[600]!, Colors.green[400]!],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.green.withValues(alpha: 0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.receipt_long,
                                      color: Colors.white, size: 24),
                                ),
                                title: Text(
                                  'Venta #${venta.id}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    formatoFecha.format(venta.fechaVenta),
                                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12),
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: Colors.red),
                                      onPressed: () =>
                                          _mostrarDialogoEliminar(venta),
                                    ),
                                    Text(
                                      formatoCurrency.format(venta.total),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green[600],
                                      ),
                                    ),
                                  ],
                                ),
                                children: [
                                  const Divider(height: 1),
                                  Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.shopping_bag_outlined, size: 18, color: Theme.of(context).colorScheme.primary),
                                            const SizedBox(width: 6),
                                            const Text(
                                              'Productos:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        ...venta.detalles
                                            .map((detalle) => Container(
                                                  margin: const EdgeInsets.only(bottom: 6),
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context).brightness == Brightness.dark
                                                        ? Colors.grey[800]
                                                        : Colors.grey[50],
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: Colors.deepPurple.withValues(alpha: 0.15),
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: Text(
                                                          '${detalle.cantidad}x',
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.deepPurple[700],
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Expanded(
                                                        child: Text(
                                                          detalle.productoNombre,
                                                          style:
                                                              const TextStyle(
                                                                  fontSize:
                                                                      14),
                                                        ),
                                                      ),
                                                      Text(
                                                        formatoCurrency
                                                            .format(detalle
                                                                .subtotal),
                                                        style:
                                                            TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 14,
                                                          color: Colors.green[700],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                )),
                                        const Divider(height: 24),
                                        _buildDetalleRow('Total:',
                                            venta.total, formatoCurrency),
                                        _buildDetalleRow('Pagado:',
                                            venta.montoPagado, formatoCurrency),
                                        _buildDetalleRow('Cambio:',
                                            venta.cambio, formatoCurrency),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                // Paginación
                if (ventasFiltradas.length > _tamanoPagina)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: _paginaActual > 0
                              ? () => setState(() => _paginaActual--)
                              : null,
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Text(
                          'Página ${_paginaActual + 1} de $totalPaginas',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        IconButton(
                          onPressed: _paginaActual < totalPaginas - 1
                              ? () => setState(() => _paginaActual++)
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

  Widget _buildChipOrden(String label, String valor) {
    final seleccionado = _ordenSeleccionado == valor;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: seleccionado,
      onSelected: (_) {
        setState(() {
          _ordenSeleccionado = valor;
          _paginaActual = 0;
        });
      },
      visualDensity: VisualDensity.compact,
      selectedColor: Colors.deepPurple.withValues(alpha: 0.2),
    );
  }

  Widget _buildDetalleRow(String label, double monto, NumberFormat formato) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          Text(
            formato.format(monto),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
