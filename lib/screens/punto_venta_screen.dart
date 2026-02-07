import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/producto.dart';
import '../models/producto_variante.dart';
import '../models/venta.dart';
import '../models/categoria.dart';
import '../services/database_helper.dart';

class PuntoVentaScreen extends StatefulWidget {
  const PuntoVentaScreen({super.key});

  @override
  State<PuntoVentaScreen> createState() => _PuntoVentaScreenState();
}

class _PuntoVentaScreenState extends State<PuntoVentaScreen> {
  final _dbHelper = DatabaseHelper.instance;
  final _searchController = TextEditingController();
  final List<DetalleVenta> _carrito = [];
  List<Producto> _productos = [];
  List<Producto> _productosFiltrados = [];
  List<Categoria> _categorias = [];
  int? _categoriaSeleccionada;
  bool _isLoading = true;
  int _paginaProductos = 0;
  static const int _tamanoPaginaProductos = 10;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    final productos = await _dbHelper.getAllProductos();
    final categorias = await _dbHelper.getCategoriasBase();
    
    // Ordenar productos: frecuentes primero, luego por nombre
    productos.sort((a, b) {
      if (a.esFrecuente && !b.esFrecuente) return -1;
      if (!a.esFrecuente && b.esFrecuente) return 1;
      return a.nombre.compareTo(b.nombre);
    });
    
    setState(() {
      _productos = productos;
      _productosFiltrados = productos;
      _categorias = categorias;
      _paginaProductos = 0;
      _isLoading = false;
    });
  }

  List<Producto> _productosPaginados(List<Producto> productos) {
    if (productos.isEmpty) return [];
    final totalPaginas = (productos.length / _tamanoPaginaProductos).ceil();
    final pagina = _paginaProductos.clamp(0, totalPaginas - 1);
    final inicio = pagina * _tamanoPaginaProductos;
    final fin = (inicio + _tamanoPaginaProductos) > productos.length
        ? productos.length
        : (inicio + _tamanoPaginaProductos);
    return productos.sublist(inicio, fin);
  }

  void _filtrarProductos() {
    setState(() {
      _paginaProductos = 0;
      _productosFiltrados = _productos.where((p) {
        final matchNombre = _searchController.text.isEmpty ||
            p.nombre.toLowerCase().contains(_searchController.text.toLowerCase());
        final matchCategoria = _categoriaSeleccionada == null ||
            p.categoriaId == _categoriaSeleccionada;
        return matchNombre && matchCategoria;
      }).toList();
    });
  }

  void _agregarAlCarrito(Producto producto) async {
    final variantes = await _dbHelper.getVariantesPorProducto(producto.id!);
    if (variantes.isNotEmpty) {
      _mostrarDialogoVariantes(producto, variantes);
      return;
    }
    
    if (producto.esPrecioPorPeso) {
      _mostrarDialogoPeso(producto);
      return;
    }

    if (producto.stock != null && producto.stock! <= 0) {
      _mostrarSnackBar('Producto sin stock disponible', Colors.red[400]!);
      return;
    }

    setState(() {
      final index = _carrito.indexWhere((d) => 
        d.productoId == producto.id && d.pesoKg == null && d.varianteId == null);
      
      if (index >= 0) {
        if (producto.stock != null && _carrito[index].cantidad >= producto.stock!) {
          _mostrarSnackBar('No hay más stock disponible', Colors.orange[400]!);
          return;
        }
        _carrito[index] = DetalleVenta(
          productoId: producto.id!,
          productoNombre: producto.nombre,
          cantidad: _carrito[index].cantidad + 1,
          precioUnitario: producto.precio,
          subtotal: (producto.precio * (_carrito[index].cantidad + 1)),
        );
      } else {
        _carrito.add(DetalleVenta(
          productoId: producto.id!,
          productoNombre: producto.nombre,
          cantidad: 1,
          precioUnitario: producto.precio,
          subtotal: producto.precio,
        ));
      }
    });
  }

  void _mostrarDialogoPeso(Producto producto) {
    final formatoCurrency = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    final pesoController = TextEditingController();
    double subtotal = 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Peso de ${producto.nombre}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: pesoController,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Peso en gramos',
                    hintText: 'Ej: 500, 1250',
                    suffixText: 'g',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (value) {
                    setDialogState(() {
                      final gramos = double.tryParse(value) ?? 0;
                      final pesoKg = gramos / 1000;
                      subtotal = pesoKg * producto.precio;
                    });
                  },
                ),
                if (subtotal > 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          formatoCurrency.format(subtotal),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  final gramos = double.tryParse(pesoController.text);
                  if (gramos == null || gramos <= 0) {
                    _mostrarSnackBar('Ingrese un peso válido', Colors.orange[400]!);
                    return;
                  }
                  final pesoKg = gramos / 1000;
                  setState(() {
                    final precioCalculado = pesoKg * producto.precio;
                    _carrito.add(DetalleVenta(
                      productoId: producto.id!,
                      productoNombre: '${producto.nombre} (${gramos.toStringAsFixed(0)}g)',
                      cantidad: 1,
                      precioUnitario: precioCalculado,
                      subtotal: precioCalculado,
                      pesoKg: pesoKg,
                    ));
                  });
                  Navigator.pop(context);
                },
                child: const Text('Agregar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _mostrarDialogoVariantes(Producto producto, List<ProductoVariante> variantes) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Variantes de ${producto.nombre}'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: variantes.length,
            itemBuilder: (context, index) {
              final variante = variantes[index];
              final precioTotal = variante.getPrecioTotal(producto.precio);
              return ListTile(
                title: Text(variante.nombre),
                subtitle: Text('${variante.contenido}${variante.unidadMedida}'),
                trailing: Text(
                  NumberFormat.currency(locale: 'es_MX', symbol: '\$').format(precioTotal),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  setState(() {
                    _carrito.add(DetalleVenta(
                      productoId: producto.id!,
                      productoNombre: '${producto.nombre} (${variante.nombre})',
                      cantidad: 1,
                      precioUnitario: precioTotal,
                      subtotal: precioTotal,
                      varianteId: variante.id,
                    ));
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _eliminarDelCarrito(int index) {
    setState(() => _carrito.removeAt(index));
  }

  void _cambiarCantidad(int index, int nuevaCantidad) {
    if (nuevaCantidad <= 0) {
      _eliminarDelCarrito(index);
      return;
    }
    
    setState(() {
      final detalle = _carrito[index];
      _carrito[index] = DetalleVenta(
        productoId: detalle.productoId,
        productoNombre: detalle.productoNombre,
        cantidad: nuevaCantidad,
        precioUnitario: detalle.precioUnitario,
        subtotal: detalle.precioUnitario * nuevaCantidad,
        pesoKg: detalle.pesoKg,
        varianteId: detalle.varianteId,
      );
    });
  }

  double get _total => _carrito.fold(0, (sum, item) => sum + item.subtotal);

  void _procesarPago() {
    if (_carrito.isEmpty) {
      _mostrarSnackBar('El carrito está vacío', Colors.orange[400]!);
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PagoBottomSheet(
        total: _total,
        onPagoCompletado: _completarVenta,
      ),
    );
  }

  Future<void> _completarVenta(double montoPagado, double cambio) async {
    final venta = Venta(
      total: _total,
      montoPagado: montoPagado,
      cambio: cambio,
      detalles: List.from(_carrito),
    );

    await _dbHelper.insertVenta(venta);
    setState(() => _carrito.clear());
    await _cargarDatos();

    if (mounted) {
      _mostrarModalCambio(cambio);
    }
  }

  void _mostrarModalCambio(double cambio) {
    final formatoCurrency = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[100],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle, color: Colors.green[700], size: 50),
            ),
            const SizedBox(height: 16),
            const Text('¡Venta Exitosa!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text('Cambio', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(
                    formatoCurrency.format(cambio),
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.green[700]),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Aceptar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarSnackBar(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatoCurrency = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    final isTablet = MediaQuery.of(context).size.width > 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header con búsqueda y filtros
                Container(
                  color: Theme.of(context).cardColor,
                  padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Punto de Venta',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      // Búsqueda
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Buscar producto...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF2C2C3E) : Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        onChanged: (_) => _filtrarProductos(),
                      ),
                      const SizedBox(height: 12),
                      // Filtros de categoría
                      SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _buildChipCategoria('Todos', null),
                            ..._categorias.map((cat) => _buildChipCategoria(cat.nombre, cat.id)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Contenido principal
                Expanded(
                  child: isTablet
                      ? Row(
                          children: [
                            // Lista de productos
                            Expanded(
                              flex: 2,
                              child: _buildListaProductos(),
                            ),
                            // Carrito (solo en tablet)
                            Container(
                              width: 350,
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(-2, 0),
                                  ),
                                ],
                              ),
                              child: _buildCarrito(formatoCurrency),
                            ),
                          ],
                        )
                      : _buildListaProductos(),
                ),
              ],
            ),
      floatingActionButton: isTablet
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _mostrarCarritoModal(formatoCurrency),
              backgroundColor: Colors.deepPurple,
              icon: Badge(
                label: Text('${_carrito.length}'),
                isLabelVisible: _carrito.isNotEmpty,
                child: const Icon(Icons.shopping_cart),
              ),
              label: Text(
                formatoCurrency.format(_total),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
    );
  }

  Widget _buildListaProductos() {
    final productosPagina = _productosPaginados(_productosFiltrados);
    final totalPaginas = _productosFiltrados.isEmpty
        ? 0
        : (_productosFiltrados.length / _tamanoPaginaProductos).ceil();
    final isTablet = MediaQuery.of(context).size.width > 600;
    return _productosFiltrados.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text('No se encontraron productos', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
              ],
            ),
          )
        : Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: productosPagina.length,
                  itemBuilder: (context, index) {
                    final producto = productosPagina[index];
                    return _buildProductoItem(producto);
                  },
                ),
              ),
              if (totalPaginas > 1)
                Container(
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: _paginaProductos > 0
                            ? () => setState(() => _paginaProductos -= 1)
                            : null,
                        icon: const Icon(Icons.chevron_left),
                        visualDensity: VisualDensity.compact,
                      ),
                      Text(
                        '${_paginaProductos + 1} / $totalPaginas',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      IconButton(
                        onPressed: (_paginaProductos + 1) < totalPaginas
                            ? () => setState(() => _paginaProductos += 1)
                            : null,
                        icon: const Icon(Icons.chevron_right),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
            ],
          );
  }

  void _mostrarCarritoModal(NumberFormat formatoCurrency) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle indicator
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(child: _buildCarrito(formatoCurrency, setModalState)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCarrito(NumberFormat formatoCurrency, [StateSetter? setModalState]) {
    return Column(
      children: [
        // Header del carrito
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.deepPurple[300]!],
            ),
          ),
          child: Column(
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart, color: Colors.white, size: 24),
                  SizedBox(width: 8),
                  Text('Carrito', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              if (_carrito.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${_carrito.length} ${_carrito.length == 1 ? 'artículo' : 'artículos'}',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          setState(() => _carrito.clear());
                          setModalState?.call(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.delete_sweep, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text('Limpiar', style: TextStyle(color: Colors.white, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        // Items del carrito
        Expanded(
          child: _carrito.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 60, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text('Carrito vacío', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  itemCount: _carrito.length,
                  itemBuilder: (context, index) {
                    final detalle = _carrito[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[800]
                            : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[700]!
                              : Colors.grey[200]!,
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Cantidad con controles compactos
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[700]
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            height: 32,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: () {
                                    _cambiarCantidad(index, detalle.cantidad - 1);
                                    setModalState?.call(() {});
                                  },
                                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Icon(Icons.remove, size: 14, color: Colors.red[400]),
                                  ),
                                ),
                                Container(
                                  constraints: const BoxConstraints(minWidth: 24),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${detalle.cantidad}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    _cambiarCantidad(index, detalle.cantidad + 1);
                                    setModalState?.call(() {});
                                  },
                                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Icon(Icons.add, size: 14, color: Colors.green[600]),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Nombre del producto
                          Expanded(
                            child: Text(
                              detalle.productoNombre,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Precio
                          Text(
                            formatoCurrency.format(detalle.subtotal),
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green[700]),
                          ),
                          // Eliminar
                          InkWell(
                            onTap: () {
                              _eliminarDelCarrito(index);
                              setModalState?.call(() {});
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Icon(Icons.close, size: 16, color: Colors.red[400]),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        // Total y botón de pago
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    Text(
                      formatoCurrency.format(_total),
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green[700]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _carrito.isEmpty ? null : () {
                    Navigator.pop(context);
                    _procesarPago();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _carrito.isEmpty ? Colors.grey[300] : Colors.green[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.payment),
                      SizedBox(width: 8),
                      Text('Procesar Pago', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChipCategoria(String label, int? catId) {
    final isSelected = _categoriaSeleccionada == catId;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() {
            _categoriaSeleccionada = catId;
            _filtrarProductos();
          });
        },
        selectedColor: Theme.of(context).brightness == Brightness.dark ? Colors.deepPurple[700] : Colors.deepPurple[100],
        checkmarkColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.deepPurple,
      ),
    );
  }

  IconData _getIconoCategoria(String? categoriaNombre) {
    switch (categoriaNombre?.toLowerCase()) {
      case 'bebidas':
        return Icons.local_bar;
      case 'refrescos':
        return Icons.liquor;
      case 'aguas':
        return Icons.water_drop;
      case 'papitas':
        return Icons.fastfood;
      case 'lácteos':
        return Icons.icecream;
      case 'carne procesada':
        return Icons.set_meal;
      case 'pan':
        return Icons.bakery_dining;
      case 'tortillas':
        return Icons.breakfast_dining;
      case 'dulces':
        return Icons.cookie;
      case 'limpieza':
        return Icons.cleaning_services;
      case 'higiene personal':
        return Icons.soap;
      case 'cigarros':
        return Icons.smoking_rooms;
      case 'frutas y verduras':
        return Icons.eco;
      case 'despensa':
        return Icons.shelves;
      case 'cocina':
        return Icons.restaurant;
      case 'harinas':
        return Icons.grain;
      case 'enlatado':
        return Icons.takeout_dining;
      case 'hielo':
        return Icons.ac_unit;
      case 'mascotas':
        return Icons.pets;
      case 'medicamentos':
        return Icons.medication;
      case 'desechables':
        return Icons.takeout_dining_outlined;
      default:
        return Icons.shopping_bag;
    }
  }

  Widget _buildProductoItem(Producto producto) {
    final formatoCurrency = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    final stockDisponible = producto.stock == null || producto.stock! > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        dense: true,
        visualDensity: const VisualDensity(vertical: -2),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        onLongPress: () => _agregarAlCarrito(producto),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: stockDisponible
                  ? [Colors.deepPurple, Colors.deepPurple[300]!]
                  : [Colors.grey[400]!, Colors.grey[300]!],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(_getIconoCategoria(producto.categoriaNombre), color: Colors.white, size: 18),
        ),
        title: Row(
          children: [
            if (producto.esFrecuente)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.orange.withValues(alpha: 0.2) : Colors.orange[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('★ Frecuente', style: TextStyle(fontSize: 8, color: Colors.orange, fontWeight: FontWeight.bold)),
              ),
            Expanded(
              child: Text(producto.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            Text(
              formatoCurrency.format(producto.precio),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green[700]),
            ),
            if (producto.stock != null) ...[
              const SizedBox(width: 12),
              Text(
                'Stock: ${producto.stock}',
                style: TextStyle(fontSize: 10, color: producto.stock! <= 5 ? Colors.red : Colors.grey[600]),
              ),
            ],
            if (producto.esStockPorPeso && producto.stockGramos != null) ...[
              const SizedBox(width: 6),
              Text(
                producto.stockGramos! >= 1000
                    ? '${(producto.stockGramos! / 1000).toStringAsFixed(1)} kg'
                    : '${producto.stockGramos!.toStringAsFixed(0)} g',
                style: const TextStyle(fontSize: 10, color: Colors.teal),
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.add_circle),
          color: Colors.deepPurple,
          iconSize: 24,
          onPressed: () => _agregarAlCarrito(producto),
        ),
      ),
    );
  }
}

class PagoBottomSheet extends StatefulWidget {
  final double total;
  final Function(double montoPagado, double cambio) onPagoCompletado;

  const PagoBottomSheet({
    super.key,
    required this.total,
    required this.onPagoCompletado,
  });

  @override
  State<PagoBottomSheet> createState() => _PagoBottomSheetState();
}

class _PagoBottomSheetState extends State<PagoBottomSheet> {
  final _montoController = TextEditingController();
  double _cambio = 0;
  int? _billeteSeleccionado;

  final List<int> _billetes = [20, 50, 100, 200, 500, 1000];

  @override
  void dispose() {
    _montoController.dispose();
    super.dispose();
  }

  void _calcularCambio(double montoPagado) {
    setState(() => _cambio = montoPagado - widget.total);
  }

  void _seleccionarBillete(int valor) {
    setState(() {
      _billeteSeleccionado = valor;
      _montoController.text = valor.toString();
    });
    _calcularCambio(valor.toDouble());
  }

  void _completarPago() {
    final montoPagado = double.tryParse(_montoController.text);
    if (montoPagado == null || montoPagado < widget.total) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('El monto debe ser mayor o igual al total'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    widget.onPagoCompletado(montoPagado, _cambio);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final formatoCurrency = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Procesar Pago', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.deepPurple.withValues(alpha: 0.12), Colors.deepPurple.withValues(alpha: 0.05)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total a pagar', style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
                      Text(
                        formatoCurrency.format(widget.total),
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Icon(Icons.payments_outlined, size: 20, color: Colors.green[700]),
                        const SizedBox(width: 6),
                        Text(
                          'Billetes:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.8,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _billetes.length,
                  itemBuilder: (context, index) {
                    final billete = _billetes[index];
                    final isSelected = _billeteSeleccionado == billete;
                    return InkWell(
                      onTap: () => _seleccionarBillete(billete),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.green[600] : Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? Colors.green[700]! : Colors.green[200]!),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.attach_money, color: isSelected ? Colors.white : Colors.green[700]),
                            Text(
                              '\$$billete',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _montoController,
                  decoration: InputDecoration(
                    labelText: 'o ingrese manualmente',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                  onChanged: (value) {
                    setState(() => _billeteSeleccionado = null);
                    final monto = double.tryParse(value);
                    if (monto != null) _calcularCambio(monto);
                  },
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: _cambio >= 0
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _cambio >= 0 ? Colors.green[300]! : Colors.red[300]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Cambio:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                      Text(
                        formatoCurrency.format(_cambio.abs()),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _cambio >= 0 ? Colors.green[700] : Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Cancelar', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _completarPago,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Confirmar Pago', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
