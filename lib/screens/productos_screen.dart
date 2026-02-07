import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/producto.dart';
import '../models/categoria.dart';
import '../models/producto_variante.dart';
import '../services/database_helper.dart';

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen>
    with SingleTickerProviderStateMixin {
  final _dbHelper = DatabaseHelper.instance;
  List<Producto> _productos = [];
  List<Categoria> _categoriasBase = [];
  List<Categoria> _subcategorias = [];
  int? _categoriaFiltro;
  int? _subcategoriaFiltro;
  int _paginaActual = 0;
  static const int _tamanoPagina = 10;
  bool _isLoading = true;
  late TabController _tabController;
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _cargarDatos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    final productos = await _dbHelper.getAllProductos();
    final categoriasBase = await _dbHelper.getCategoriasBase();
    setState(() {
      _productos = productos;
      _categoriasBase = categoriasBase;
      _paginaActual = 0;
      _isLoading = false;
    });
  }

  Future<void> _cargarSubcategorias(int categoriaId) async {
    final subs = await _dbHelper.getSubcategorias(categoriaId);
    setState(() {
      _subcategorias = subs;
      _subcategoriaFiltro = null;
    });
  }

  Future<void> _eliminarProducto(int id) async {
    await _dbHelper.deleteProducto(id);
    _cargarDatos();
  }

  void _mostrarDialogoConfirmacion(Producto producto) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar producto'),
        content: Text('¿Está seguro de eliminar "${producto.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _eliminarProducto(producto.id!);
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

  void _mostrarDialogoDevolucion(Producto producto) {
    final cantidadController = TextEditingController(text: '1');
    final montoController = TextEditingController(text: producto.precio.toStringAsFixed(2));
    final conceptoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.assignment_return, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('Devolución'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Producto: ${producto.nombre}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              TextField(
                controller: cantidadController,
                decoration: InputDecoration(
                  labelText: 'Cantidad',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                  filled: true,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: (val) {
                  final cant = int.tryParse(val) ?? 1;
                  montoController.text =
                      (producto.precio * cant).toStringAsFixed(2);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: montoController,
                decoration: InputDecoration(
                  labelText: 'Monto a devolver',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                  filled: true,
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: conceptoController,
                decoration: InputDecoration(
                  labelText: 'Concepto (opcional)',
                  hintText: 'Ej: Producto dañado',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                  filled: true,
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final cantidad = int.tryParse(cantidadController.text) ?? 1;
              final monto =
                  double.tryParse(montoController.text) ?? producto.precio;
              Navigator.pop(context);
              await _dbHelper.insertDevolucion(
                productoId: producto.id!,
                productoNombre: producto.nombre,
                cantidad: cantidad,
                monto: monto,
                concepto: conceptoController.text.isEmpty
                    ? null
                    : conceptoController.text,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Devolución registrada'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            icon: const Icon(Icons.assignment_return),
            label: const Text('Registrar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  List<Producto> get _productosFiltrados {
    var filtrados = _productos;
    
    if (_categoriaFiltro != null) {
      filtrados = filtrados.where((p) => p.categoriaId == _categoriaFiltro).toList();
    }
    
    if (_subcategoriaFiltro != null) {
      filtrados = filtrados.where((p) => p.subcategoriaId == _subcategoriaFiltro).toList();
    }
    
    return filtrados;
  }

  List<Producto> _productosPaginados(List<Producto> productos) {
    if (productos.isEmpty) {
      return [];
    }
    final totalPaginas = (productos.length / _tamanoPagina).ceil();
    final pagina = math.min(_paginaActual, math.max(totalPaginas - 1, 0));
    final inicio = pagina * _tamanoPagina;
    final fin = (inicio + _tamanoPagina) > productos.length
        ? productos.length
        : (inicio + _tamanoPagina);
    return productos.sublist(inicio, fin);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Productos e Inventario',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(
                icon: Icon(Icons.shopping_bag_rounded),
                text: 'Productos',
              ),
              Tab(
                icon: Icon(Icons.inventory_rounded),
                text: 'Inventario',
              ),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildProductosTab(),
            InventarioTab(key: ValueKey(_refreshKey)),
          ],
        ),
        floatingActionButton: _tabController.index == 0
            ? FloatingActionButton(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FormProductoScreen(),
                    ),
                  );
                  _cargarDatos();
                  setState(() => _refreshKey++);
                },
                child: const Icon(Icons.add),
              )
            : null,
      ),
    );
  }

  Widget _buildProductosTab() {
    final formatoCurrency = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    final productosMostrar = _productosFiltrados;
    final productosPagina = _productosPaginados(productosMostrar);
    final totalPaginas = productosMostrar.isEmpty
      ? 0
      : (productosMostrar.length / _tamanoPagina).ceil();

    return Column(
        children: [
          // Filtro de categorías
          if (_categoriasBase.isNotEmpty)
            Container(
              color: Theme.of(context).cardColor,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Categorías',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategoriaChip('Todos', null),
                        const SizedBox(width: 8),
                        ..._categoriasBase.map(
                          (cat) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildCategoriaChip(cat.nombre, cat.id),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Subcategorías (si hay una categoría seleccionada)
                  if (_categoriaFiltro != null && _subcategorias.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Subcategorías',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildSubcategoriaChip('Todas', null),
                          const SizedBox(width: 8),
                          ..._subcategorias.map(
                            (subcat) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _buildSubcategoriaChip(subcat.nombre, subcat.id),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : productosMostrar.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined,
                                size: 80, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'No hay productos',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: productosPagina.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (context, index) {
                          final producto = productosPagina[index];
                          final stockBajo =
                              producto.stock != null && producto.stock! <= 5;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ListTile(
                              dense: true,
                              visualDensity: const VisualDensity(vertical: -2),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 4),
                              leading: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.deepPurple,
                                      Colors.deepPurple[300]!
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    producto.nombre[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                producto.nombre,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 1),
                                  Row(
                                    children: [
                                      if (producto.categoriaNombre != null)
                                        Container(
                                          margin: const EdgeInsets.only(right: 6),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.deepPurple.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            producto.categoriaNombre!,
                                            style: const TextStyle(
                                              fontSize: 9,
                                              color: Colors.deepPurple,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      if (producto.subcategoriaNombre != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.deepPurple[200]!.withValues(alpha: 0.3),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            producto.subcategoriaNombre!,
                                            style: TextStyle(
                                              fontSize: 9,
                                              color: Colors.deepPurple[700],
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text(
                                        producto.esPrecioPorPeso
                                            ? '${formatoCurrency.format(producto.precio)}/kg'
                                            : formatoCurrency.format(producto.precio),
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      if (producto.esPrecioPorPeso) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.scale, size: 12, color: Colors.orange),
                                              SizedBox(width: 4),
                                              Text(
                                                'Por peso',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  color: Colors.orange,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      if (producto.stock != null) ...[
                                        const SizedBox(width: 12),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: stockBajo
                                                ? Colors.red.withValues(alpha: 0.1)
                                                : Colors.blue.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Stock: ${producto.stock}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: stockBajo
                                                  ? Colors.red
                                                  : Colors.blue,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                      if (producto.esStockPorPeso && producto.stockGramos != null) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: Colors.teal.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            producto.stockGramos! >= 1000
                                                ? '${(producto.stockGramos! / 1000).toStringAsFixed(1)} kg'
                                                : '${producto.stockGramos!.toStringAsFixed(0)} g',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.teal,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert),
                                onSelected: (value) async {
                                  switch (value) {
                                    case 'editar':
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              FormProductoScreen(
                                                  producto: producto),
                                        ),
                                      );
                                      _cargarDatos();
                                      break;
                                    case 'eliminar':
                                      _mostrarDialogoConfirmacion(producto);
                                      break;
                                    case 'devolucion':
                                      _mostrarDialogoDevolucion(producto);
                                      break;
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'editar',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                                        SizedBox(width: 8),
                                        Text('Editar'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'devolucion',
                                    child: Row(
                                      children: [
                                        Icon(Icons.assignment_return, color: Colors.orange, size: 20),
                                        SizedBox(width: 8),
                                        Text('Devolución'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'eliminar',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                        SizedBox(width: 8),
                                        Text('Eliminar'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
            if (!_isLoading && productosMostrar.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 88, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: _paginaActual > 0
                          ? () {
                              setState(() => _paginaActual -= 1);
                            }
                          : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Text(
                      'Página ${_paginaActual + 1} de $totalPaginas',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    IconButton(
                      onPressed: (_paginaActual + 1) < totalPaginas
                          ? () {
                              setState(() => _paginaActual += 1);
                            }
                          : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),
        ],
      );
  }

  Widget _buildCategoriaChip(String label, int? categoriaId) {
    final isSelected = _categoriaFiltro == categoriaId;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _categoriaFiltro = selected ? categoriaId : null;
          _subcategoriaFiltro = null;
          _subcategorias = [];
          _paginaActual = 0;
        });
        
        if (selected && categoriaId != null) {
          _cargarSubcategorias(categoriaId);
        }
      },
      selectedColor: Colors.deepPurple,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[200],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _buildSubcategoriaChip(String label, int? subcategoriaId) {
    final isSelected = _subcategoriaFiltro == subcategoriaId;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _subcategoriaFiltro = selected ? subcategoriaId : null;
          _paginaActual = 0;
        });
      },
      selectedColor: Colors.deepPurple[300],
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[700] : Colors.grey[100],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

class FormProductoScreen extends StatefulWidget {
  final Producto? producto;

  const FormProductoScreen({super.key, this.producto});

  @override
  State<FormProductoScreen> createState() => _FormProductoScreenState();
}

class _FormProductoScreenState extends State<FormProductoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _precioController = TextEditingController();
  final _stockController = TextEditingController();
  final _stockGramosController = TextEditingController();
  final _dbHelper = DatabaseHelper.instance;
  
  List<Categoria> _categoriasBase = [];
  List<Categoria> _subcategorias = [];
  List<ProductoVariante> _variantes = [];
  int? _categoriaSeleccionada;
  int? _subcategoriaSeleccionada;
  bool _esPrecioPorPeso = false;
  bool _esFrecuente = false;
  bool _esStockPorPeso = false;
  bool _tieneVariantes = false;

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
    if (widget.producto != null) {
      _nombreController.text = widget.producto!.nombre;
      _descripcionController.text = widget.producto!.descripcion ?? '';
      _precioController.text = widget.producto!.precio.toString();
      _stockController.text = widget.producto!.stock?.toString() ?? '';
      _stockGramosController.text = widget.producto!.stockGramos?.toStringAsFixed(0) ?? '';
      _categoriaSeleccionada = widget.producto!.categoriaId;
      _subcategoriaSeleccionada = widget.producto!.subcategoriaId;
      _esPrecioPorPeso = widget.producto!.esPrecioPorPeso;
      _esFrecuente = widget.producto!.esFrecuente;
      _esStockPorPeso = widget.producto!.esStockPorPeso;
      
      if (_categoriaSeleccionada != null) {
        _cargarSubcategorias(_categoriaSeleccionada!);
      }
      
      _cargarVariantes();
    }
  }

  Future<void> _cargarCategorias() async {
    final categorias = await _dbHelper.getCategoriasBase();
    setState(() => _categoriasBase = categorias);
  }

  Future<void> _cargarSubcategorias(int categoriaId) async {
    final subs = await _dbHelper.getSubcategorias(categoriaId);
    setState(() => _subcategorias = subs);
  }
  
  Future<void> _cargarVariantes() async {
    if (widget.producto?.id != null) {
      final variantes = await _dbHelper.getVariantesPorProducto(widget.producto!.id!);
      setState(() {
        _variantes = variantes;
        _tieneVariantes = variantes.isNotEmpty;
      });
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _precioController.dispose();
    _stockController.dispose();
    _stockGramosController.dispose();
    super.dispose();
  }

  Future<void> _guardarProducto() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Validar que si tiene variantes, hay al menos una
    if (_tieneVariantes && _variantes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe agregar al menos una variante'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final producto = Producto(
      id: widget.producto?.id,
      nombre: _nombreController.text,
      descripcion: _descripcionController.text.isEmpty
          ? null
          : _descripcionController.text,
      precio: double.parse(_precioController.text),
      stock: _stockController.text.isEmpty
          ? null
          : int.parse(_stockController.text),
      categoriaId: _categoriaSeleccionada,
      subcategoriaId: _subcategoriaSeleccionada,
      esPrecioPorPeso: _esPrecioPorPeso,
      esFrecuente: _esFrecuente,
      esStockPorPeso: _esStockPorPeso,
      stockGramos: _stockGramosController.text.isEmpty
          ? null
          : double.tryParse(_stockGramosController.text),
    );

    int productoId;
    if (widget.producto == null) {
      productoId = await _dbHelper.insertProducto(producto);
    } else {
      await _dbHelper.updateProducto(producto);
      productoId = producto.id!;
    }
    
    // Guardar variantes si tiene variantes habilitado
    if (_tieneVariantes) {
      for (var variante in _variantes) {
        if (variante.id == null) {
          // Nueva variante
          await _dbHelper.insertProductoVariante(
            variante.copyWith(productoId: productoId),
          );
        } else {
          // Actualizar variante existente
          await _dbHelper.updateProductoVariante(variante);
        }
      }
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }
  
  void _mostrarDialogoVariante({ProductoVariante? variante}) {
    final nombreController = TextEditingController(text: variante?.nombre);
    final contenidoController = TextEditingController(
      text: variante?.contenido.toString() ?? '',
    );
    final precioAdicionalController = TextEditingController(
      text: variante?.precioAdicional.toString() ?? '0',
    );
    final stockController = TextEditingController(
      text: variante?.stockEspecifico?.toString() ?? '',
    );
    String unidadMedida = variante?.unidadMedida ?? 'ml';
    
    // Determinar unidad por defecto según categoría
    if (_categoriaSeleccionada != null) {
      final categoriaNombre = _categoriasBase
          .firstWhere((c) => c.id == _categoriaSeleccionada)
          .nombre
          .toLowerCase();
      
      if (categoriaNombre.contains('bebida') || categoriaNombre.contains('líquido')) {
        unidadMedida = variante?.unidadMedida ?? 'ml';
      } else if (categoriaNombre.contains('comida') || categoriaNombre.contains('alimento')) {
        unidadMedida = variante?.unidadMedida ?? 'g';
      }
    }
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.blue.withValues(alpha: 0.2)
                        : Colors.blue[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.widgets, color: Colors.blue[700], size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    variante == null ? 'Nueva Variante' : 'Editar Variante',
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: nombreController,
                    decoration: InputDecoration(
                      labelText: 'Nombre de la variante *',
                      hintText: 'Ej: 500ml, 1L, 250g',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: contenidoController,
                          decoration: InputDecoration(
                            labelText: 'Contenido *',
                            hintText: 'Ej: 500',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: unidadMedida,
                          decoration: InputDecoration(
                            labelText: 'Unidad',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'ml', child: Text('ml')),
                            DropdownMenuItem(value: 'L', child: Text('L')),
                            DropdownMenuItem(value: 'g', child: Text('g')),
                            DropdownMenuItem(value: 'kg', child: Text('kg')),
                            DropdownMenuItem(value: 'pz', child: Text('pz')),
                          ],
                          onChanged: (value) {
                            setStateDialog(() {
                              unidadMedida = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: precioAdicionalController,
                    decoration: InputDecoration(
                      labelText: 'Precio adicional (sobre precio base)',
                      prefixText: '\$ ',
                      hintText: '0 si no tiene costo extra',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      helperText: 'Costo extra de esta variante',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: stockController,
                    decoration: InputDecoration(
                      labelText: 'Stock específico (opcional)',
                      hintText: 'Stock de esta variante',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nombreController.text.isEmpty ||
                      contenidoController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Complete todos los campos requeridos'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  
                  final nuevaVariante = ProductoVariante(
                    id: variante?.id,
                    productoId: widget.producto?.id ?? 0,
                    nombre: nombreController.text,
                    contenido: double.parse(contenidoController.text),
                    unidadMedida: unidadMedida,
                    precioAdicional: double.tryParse(precioAdicionalController.text) ?? 0,
                    stockEspecifico: stockController.text.isEmpty
                        ? null
                        : int.parse(stockController.text),
                  );
                  
                  setState(() {
                    if (variante == null) {
                      _variantes.add(nuevaVariante);
                    } else {
                      final index = _variantes.indexWhere((v) => v.id == variante.id);
                      if (index != -1) {
                        _variantes[index] = nuevaVariante;
                      }
                    }
                  });
                  
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(variante == null ? 'Agregar' : 'Actualizar'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  void _eliminarVariante(ProductoVariante variante) async {
    if (variante.id != null) {
      await _dbHelper.deleteProductoVariante(variante.id!);
    }
    setState(() {
      _variantes.remove(variante);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.producto == null ? 'Nuevo Producto' : 'Editar Producto',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _nombreController,
              decoration: InputDecoration(
                labelText: 'Nombre *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                prefixIcon: const Icon(Icons.shopping_bag_outlined),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'El nombre es requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _categoriaSeleccionada,
              decoration: InputDecoration(
                labelText: 'Categoría',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                prefixIcon: const Icon(Icons.label_outline),
              ),
              items: [
                const DropdownMenuItem<int>(
                  value: null,
                  child: Text('Sin categoría'),
                ),
                ..._categoriasBase.map((cat) {
                  return DropdownMenuItem<int>(
                    value: cat.id,
                    child: Text(cat.nombre),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _categoriaSeleccionada = value;
                  _subcategoriaSeleccionada = null;
                  _subcategorias = [];
                });
                
                if (value != null) {
                  _cargarSubcategorias(value);
                }
              },
            ),
            const SizedBox(height: 16),
            // Subcategoría (solo si hay categoría seleccionada)
            if (_categoriaSeleccionada != null && _subcategorias.isNotEmpty)
              Column(
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: _subcategoriaSeleccionada,
                    decoration: InputDecoration(
                      labelText: 'Subcategoría',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      prefixIcon: const Icon(Icons.label),
                    ),
                    items: [
                      const DropdownMenuItem<int>(
                        value: null,
                        child: Text('Sin subcategoría'),
                      ),
                      ..._subcategorias.map((subcat) {
                        return DropdownMenuItem<int>(
                          value: subcat.id,
                          child: Text(subcat.nombre),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() => _subcategoriaSeleccionada = value);
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            TextFormField(
              controller: _descripcionController,
              decoration: InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                prefixIcon: const Icon(Icons.description_outlined),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            // Checkbox de precio por peso
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.orange.withValues(alpha: 0.15)
                    : Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.orange.withValues(alpha: 0.4)
                    : Colors.orange[200]!),
              ),
              child: CheckboxListTile(
                value: _esPrecioPorPeso,
                onChanged: (value) {
                  setState(() => _esPrecioPorPeso = value ?? false);
                },
                title: const Row(
                  children: [
                    Icon(Icons.scale, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Precio por gramaje (kg)',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                subtitle: const Text(
                  'Marcar si el producto se vende por peso (frutas, verduras, etc.)',
                  style: TextStyle(fontSize: 12),
                ),
                activeColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Checkbox de producto frecuente
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.amber.withValues(alpha: 0.15)
                    : Colors.amber[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.amber.withValues(alpha: 0.4)
                    : Colors.amber[200]!),
              ),
              child: CheckboxListTile(
                value: _esFrecuente,
                onChanged: (value) {
                  setState(() => _esFrecuente = value ?? false);
                },
                title: const Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Producto Frecuente',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                subtitle: const Text(
                  'Aparecerá al inicio de la lista en punto de venta',
                  style: TextStyle(fontSize: 12),
                ),
                activeColor: Colors.amber,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Sección de Variantes
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.blue.withValues(alpha: 0.15)
                    : Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.blue.withValues(alpha: 0.4)
                    : Colors.blue[200]!),
              ),
              child: Column(
                children: [
                  CheckboxListTile(
                    value: _tieneVariantes,
                    onChanged: (value) {
                      setState(() => _tieneVariantes = value ?? false);
                    },
                    title: const Row(
                      children: [
                        Icon(Icons.widgets, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Producto con variantes',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    subtitle: const Text(
                      'Diferentes presentaciones (500ml, 1L, 250g, etc.)',
                      style: TextStyle(fontSize: 12),
                    ),
                    activeColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  if (_tieneVariantes) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Variantes (${_variantes.length})',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: _mostrarDialogoVariante,
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Agregar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_variantes.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Text(
                                'No hay variantes. Presiona "Agregar" para crear una.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          else
                            ...                _variantes.map((variante) {
                              final formatoCurrency = NumberFormat.currency(
                                locale: 'es_MX',
                                symbol: '\$',
                              );
                              final precioBase = double.tryParse(_precioController.text) ?? 0;
                              final precioTotal = variante.getPrecioTotal(precioBase);
                              
                              return Container(
                                margin: const EdgeInsets.only(top: 8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.blue.withValues(alpha: 0.4)
                                      : Colors.blue[200]!),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.blue[100],
                                    child: Icon(
                                      Icons.local_offer,
                                      color: Colors.blue[700],
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    variante.nombre,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${variante.contenido}${variante.unidadMedida} • ${formatoCurrency.format(precioTotal)}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 18),
                                        color: Colors.blue,
                                        onPressed: () => _mostrarDialogoVariante(
                                          variante: variante,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, size: 18),
                                        color: Colors.red,
                                        onPressed: () => _eliminarVariante(variante),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _precioController,
              decoration: InputDecoration(
                labelText: _esPrecioPorPeso ? 'Precio por kg *' : 'Precio *',
                prefixText: '\$ ',
                suffixText: _esPrecioPorPeso ? '/kg' : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                prefixIcon: const Icon(Icons.attach_money),
                helperText: _esPrecioPorPeso
                    ? 'Precio por kilogramo del producto'
                    : null,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'El precio es requerido';
                }
                if (double.tryParse(value) == null) {
                  return 'Ingrese un precio válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _stockController,
              decoration: InputDecoration(
                labelText: 'Stock en unidades (opcional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                prefixIcon: const Icon(Icons.inventory_2_outlined),
                helperText: 'Dejar vacío si no se conoce el stock',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),
            // Opción de stock por gramaje
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.teal.withValues(alpha: 0.15)
                    : Colors.teal[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.teal.withValues(alpha: 0.4)
                    : Colors.teal[200]!),
              ),
              child: Column(
                children: [
                  CheckboxListTile(
                    value: _esStockPorPeso,
                    onChanged: (value) {
                      setState(() => _esStockPorPeso = value ?? false);
                    },
                    title: const Row(
                      children: [
                        Icon(Icons.scale, color: Colors.teal, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Stock por gramaje',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    subtitle: const Text(
                      'Registrar stock adicional en gramos (ej: bolsas de hielo, granel)',
                      style: TextStyle(fontSize: 12),
                    ),
                    activeColor: Colors.teal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  if (_esStockPorPeso) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: TextFormField(
                        controller: _stockGramosController,
                        decoration: InputDecoration(
                          labelText: 'Stock en gramos',
                          suffixText: 'g',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          prefixIcon: const Icon(Icons.scale, color: Colors.teal),
                          helperText: 'Ej: 5000 = 5 kg',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _guardarProducto,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                widget.producto == null ? 'Guardar Producto' : 'Actualizar Producto',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== INVENTARIO TAB ====================

class InventarioTab extends StatefulWidget {
  const InventarioTab({super.key});

  @override
  State<InventarioTab> createState() => _InventarioTabState();
}

class _InventarioTabState extends State<InventarioTab> {
  final _dbHelper = DatabaseHelper.instance;
  List<Producto> _productos = [];
  List<Categoria> _categoriasBase = [];
  bool _isLoading = true;
  final Set<int> _seleccionados = {};
  bool _modoSeleccion = false;
  int? _categoriaFiltro;
  String _busqueda = '';
  final _busquedaController = TextEditingController();
  int _paginaActual = 0;
  static const int _tamanoPagina = 10;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    final productos = await _dbHelper.getAllProductos();
    final categorias = await _dbHelper.getCategoriasBase();
    setState(() {
      _productos = productos;
      _categoriasBase = categorias;
      _isLoading = false;
      _paginaActual = 0;
    });
  }

  List<Producto> get _productosFiltrados {
    var filtrados = _productos;
    if (_categoriaFiltro != null) {
      filtrados = filtrados.where((p) => p.categoriaId == _categoriaFiltro).toList();
    }
    if (_busqueda.isNotEmpty) {
      final query = _busqueda.toLowerCase();
      filtrados = filtrados.where((p) =>
          p.nombre.toLowerCase().contains(query) ||
          (p.marca?.toLowerCase().contains(query) ?? false)).toList();
    }
    return filtrados;
  }

  void _toggleSeleccion(int id) {
    setState(() {
      if (_seleccionados.contains(id)) {
        _seleccionados.remove(id);
        if (_seleccionados.isEmpty) {
          _modoSeleccion = false;
        }
      } else {
        _seleccionados.add(id);
      }
    });
  }

  void _iniciarSeleccion(int id) {
    setState(() {
      _modoSeleccion = true;
      _seleccionados.add(id);
    });
  }

  void _cancelarSeleccion() {
    setState(() {
      _modoSeleccion = false;
      _seleccionados.clear();
    });
  }

  void _seleccionarTodos() {
    setState(() {
      final filtrados = _productosFiltrados;
      if (_seleccionados.length == filtrados.length) {
        _seleccionados.clear();
        _modoSeleccion = false;
      } else {
        _seleccionados.clear();
        _seleccionados.addAll(filtrados.map((p) => p.id!));
      }
    });
  }

  Future<void> _asignarMarca() async {
    if (_seleccionados.isEmpty) return;

    // Obtener la marca actual si todos los seleccionados tienen la misma
    final seleccionadosProductos = _productos.where((p) => _seleccionados.contains(p.id)).toList();
    final marcas = seleccionadosProductos.map((p) => p.marca).toSet();
    final marcaActual = marcas.length == 1 ? marcas.first : null;

    final marcaController = TextEditingController(text: marcaActual ?? '');

    final resultado = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.deepPurple.withValues(alpha: 0.2)
                    : Colors.deepPurple[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.label, color: Colors.deepPurple, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Asignar marca (${_seleccionados.length} productos)',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: TextField(
          controller: marcaController,
          decoration: InputDecoration(
            labelText: 'Marca',
            hintText: 'Ej: Coca-Cola, Bimbo, Gamesa...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            prefixIcon: const Icon(Icons.label_outline),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          if (marcaActual != null && marcaActual.isNotEmpty)
            TextButton(
              onPressed: () => Navigator.pop(context, ''),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Quitar marca'),
            ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, marcaController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (resultado != null) {
      await _dbHelper.updateProductoMarca(
        _seleccionados.toList(),
        resultado.isEmpty ? null : resultado,
      );
      _cancelarSeleccion();
      await _cargarDatos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resultado.isEmpty
              ? 'Marca removida'
              : 'Marca "$resultado" asignada')),
        );
      }
    }
  }

  Future<void> _editarStock(Producto producto) async {
    final stockController = TextEditingController(
      text: producto.stock?.toString() ?? '',
    );
    final stockGramosController = TextEditingController(
      text: producto.stockGramos?.toStringAsFixed(0) ?? '',
    );

    final resultado = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Stock: ${producto.nombre}', style: const TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: stockController,
              decoration: InputDecoration(
                labelText: 'Stock en unidades',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                prefixIcon: const Icon(Icons.inventory),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autofocus: true,
            ),
            if (producto.esStockPorPeso) ...[
              const SizedBox(height: 16),
              TextField(
                controller: stockGramosController,
                decoration: InputDecoration(
                  labelText: 'Stock en gramos',
                  suffixText: 'g',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  prefixIcon: const Icon(Icons.scale, color: Colors.teal),
                  helperText: 'Ej: 5000 = 5 kg',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
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
              final val = int.tryParse(stockController.text);
              final gramos = double.tryParse(stockGramosController.text);
              Navigator.pop(context, {'stock': val, 'gramos': gramos});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (resultado != null) {
      if (resultado['stock'] != null) {
        await _dbHelper.updateProductoStock(producto.id!, resultado['stock'] as int);
      }
      if (producto.esStockPorPeso && resultado['gramos'] != null) {
        await _dbHelper.updateProductoStockGramos(producto.id!, resultado['gramos'] as double);
      }
      await _cargarDatos();
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatoCurrency = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    final productosFiltrados = _productosFiltrados;
    final totalPaginas = productosFiltrados.isEmpty ? 0 : (productosFiltrados.length / _tamanoPagina).ceil();
    final pagina = _paginaActual.clamp(0, totalPaginas > 0 ? totalPaginas - 1 : 0);
    final inicio = pagina * _tamanoPagina;
    final fin = (inicio + _tamanoPagina) > productosFiltrados.length
        ? productosFiltrados.length
        : (inicio + _tamanoPagina);
    final productosPagina = productosFiltrados.isEmpty ? <Producto>[] : productosFiltrados.sublist(inicio, fin);

    return Column(
      children: [
        // Barra de acciones cuando hay selección
        if (_modoSeleccion)
          Container(
            color: Colors.deepPurple,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: _cancelarSeleccion,
                ),
                Text(
                  '${_seleccionados.length} seleccionado(s)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _seleccionarTodos,
                  icon: const Icon(Icons.select_all, color: Colors.white, size: 18),
                  label: const Text('Todos', style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
                TextButton.icon(
                  onPressed: _seleccionados.isNotEmpty ? _asignarMarca : null,
                  icon: const Icon(Icons.label, color: Colors.white),
                  label: const Text('Marca', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        // Barra de búsqueda
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _busquedaController,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o marca...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _busqueda.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _busquedaController.clear();
                        setState(() {
                          _busqueda = '';
                          _paginaActual = 0;
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              isDense: true,
            ),
            onChanged: (value) => setState(() {
              _busqueda = value;
              _paginaActual = 0;
            }),
          ),
        ),
        // Filtro de categorías
        if (_categoriasBase.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFiltroChip('Todos', null),
                  const SizedBox(width: 8),
                  ..._categoriasBase.map(
                    (cat) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildFiltroChip(cat.nombre, cat.id),
                    ),
                  ),
                ],
              ),
            ),
          ),
        // Hint de selección
        if (!_modoSeleccion)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Icon(Icons.touch_app, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  'Mantén presionado para seleccionar varios',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500], fontStyle: FontStyle.italic),
                ),
                const Spacer(),
                Text(
                  '${productosFiltrados.length} productos',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        // Lista de productos
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : productosFiltrados.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined,
                              size: 80, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            'No hay productos',
                            style: TextStyle(fontSize: 18, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: productosPagina.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        final producto = productosPagina[index];
                        final isSelected = _seleccionados.contains(producto.id);
                        final stockBajo = producto.stock != null && producto.stock! <= 5;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).brightness == Brightness.dark
                                    ? Colors.deepPurple.withValues(alpha: 0.3)
                                    : Colors.deepPurple.withValues(alpha: 0.08)
                                : Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: isSelected
                                ? Border.all(color: Colors.deepPurple, width: 1.5)
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            onTap: _modoSeleccion
                                ? () => _toggleSeleccion(producto.id!)
                                : () => _editarStock(producto),
                            onLongPress: !_modoSeleccion
                                ? () => _iniciarSeleccion(producto.id!)
                                : null,
                            leading: _modoSeleccion
                                ? Checkbox(
                                    value: isSelected,
                                    onChanged: (_) => _toggleSeleccion(producto.id!),
                                    activeColor: Colors.deepPurple,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  )
                                : Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Colors.deepPurple, Colors.deepPurple[300]!],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        producto.nombre[0].toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                            title: Text(
                              producto.nombre,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    // Marca badge
                                    if (producto.marca != null && producto.marca!.isNotEmpty)
                                      Container(
                                        margin: const EdgeInsets.only(right: 6),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.teal.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.label, size: 10, color: Colors.teal),
                                            const SizedBox(width: 3),
                                            Text(
                                              producto.marca!,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.teal,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    // Categoría badge
                                    if (producto.categoriaNombre != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.deepPurple.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          producto.categoriaNombre!,
                                          style: const TextStyle(
                                            fontSize: 9,
                                            color: Colors.deepPurple,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      formatoCurrency.format(producto.precio),
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Stock badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: producto.stock == null
                                            ? Colors.grey.withValues(alpha: 0.15)
                                            : stockBajo
                                                ? Colors.red.withValues(alpha: 0.1)
                                                : Colors.blue.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        producto.stock == null
                                            ? 'Sin stock'
                                            : 'Stock: ${producto.stock}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: producto.stock == null
                                              ? Colors.grey
                                              : stockBajo
                                                  ? Colors.red
                                                  : Colors.blue,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    if (producto.esStockPorPeso && producto.stockGramos != null) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.teal.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          producto.stockGramos! >= 1000
                                              ? '${(producto.stockGramos! / 1000).toStringAsFixed(1)} kg'
                                              : '${producto.stockGramos!.toStringAsFixed(0)} g',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.teal,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                            trailing: !_modoSeleccion
                                ? IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 20),
                                    color: Colors.blue,
                                    tooltip: 'Editar stock',
                                    onPressed: () => _editarStock(producto),
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
        ),
        // Paginación
        if (!_isLoading && totalPaginas > 1)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _paginaActual > 0
                      ? () => setState(() => _paginaActual -= 1)
                      : null,
                  icon: const Icon(Icons.chevron_left),
                  visualDensity: VisualDensity.compact,
                ),
                Text(
                  'Página ${_paginaActual + 1} de $totalPaginas',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                IconButton(
                  onPressed: (_paginaActual + 1) < totalPaginas
                      ? () => setState(() => _paginaActual += 1)
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

  Widget _buildFiltroChip(String label, int? categoriaId) {
    final isSelected = _categoriaFiltro == categoriaId;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _categoriaFiltro = selected ? categoriaId : null;
          _seleccionados.clear();
          _modoSeleccion = false;
          _paginaActual = 0;
        });
      },
      selectedColor: Colors.deepPurple,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[800]
          : Colors.grey[200],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
