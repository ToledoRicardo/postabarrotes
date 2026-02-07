import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/proveedor.dart';
import '../models/compra.dart';
import '../models/producto.dart';
import '../services/database_helper.dart';

class ProveedoresScreen extends StatefulWidget {
  const ProveedoresScreen({super.key});

  @override
  State<ProveedoresScreen> createState() => _ProveedoresScreenState();
}

class _ProveedoresScreenState extends State<ProveedoresScreen>
    with SingleTickerProviderStateMixin {
  final _dbHelper = DatabaseHelper.instance;
  List<Proveedor> _proveedores = [];
  bool _isLoading = true;
  late TabController _tabController;
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarProveedores();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarProveedores() async {
    setState(() => _isLoading = true);
    final proveedores = await _dbHelper.getAllProveedores();
    setState(() {
      _proveedores = proveedores;
      _isLoading = false;
    });
  }

  Future<void> _eliminarProveedor(int id) async {
    await _dbHelper.deleteProveedor(id);
    _cargarProveedores();
  }

  void _mostrarDialogoConfirmacion(Proveedor proveedor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('Eliminar proveedor'),
          ],
        ),
        content: Text('¿Está seguro de eliminar "${proveedor.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _eliminarProveedor(proveedor.id!);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            'Proveedores y Compras',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withOpacity(0.8),
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
                icon: Icon(Icons.business_rounded),
                text: 'Proveedores',
              ),
              Tab(
                icon: Icon(Icons.shopping_cart_rounded),
                text: 'Compras',
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
            _buildProveedoresTab(),
            ComprasTab(key: ValueKey(_refreshKey)),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            if (_tabController.index == 0) {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FormProveedorScreen(),
                ),
              );
              _cargarProveedores();
            } else {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FormCompraScreen(),
                ),
              );
              setState(() => _refreshKey++);
            }
          },
          child: const Icon(Icons.add),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildProveedoresTab() {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_proveedores.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business_outlined, size: 100, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No hay proveedores registrados',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            Text(
              'Toca el botón (+) para agregar',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _proveedores.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final proveedor = _proveedores[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  proveedor.nombre[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            title: Text(
              proveedor.nombre,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (proveedor.telefono != null)
                    Row(
                      children: [
                        Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Text(
                          proveedor.telefono!,
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  if (proveedor.email != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(Icons.email, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              proveedor.email!,
                              style: TextStyle(color: Colors.grey[700]),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (proveedor.direccion != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              proveedor.direccion!,
                              style: TextStyle(color: Colors.grey[700]),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit_rounded, color: theme.colorScheme.primary),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            FormProveedorScreen(proveedor: proveedor),
                      ),
                    );
                    _cargarProveedores();
                  },
                  tooltip: 'Editar',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_rounded, color: Colors.red),
                  onPressed: () => _mostrarDialogoConfirmacion(proveedor),
                  tooltip: 'Eliminar',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class FormProveedorScreen extends StatefulWidget {
  final Proveedor? proveedor;

  const FormProveedorScreen({super.key, this.proveedor});

  @override
  State<FormProveedorScreen> createState() => _FormProveedorScreenState();
}

class _FormProveedorScreenState extends State<FormProveedorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _direccionController = TextEditingController();
  final _dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    if (widget.proveedor != null) {
      _nombreController.text = widget.proveedor!.nombre;
      _telefonoController.text = widget.proveedor!.telefono ?? '';
      _emailController.text = widget.proveedor!.email ?? '';
      _direccionController.text = widget.proveedor!.direccion ?? '';
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  Future<void> _guardarProveedor() async {
    if (!_formKey.currentState!.validate()) return;

    final proveedor = Proveedor(
      id: widget.proveedor?.id,
      nombre: _nombreController.text,
      telefono:
          _telefonoController.text.isEmpty ? null : _telefonoController.text,
      email: _emailController.text.isEmpty ? null : _emailController.text,
      direccion:
          _direccionController.text.isEmpty ? null : _direccionController.text,
    );

    if (widget.proveedor == null) {
      await _dbHelper.insertProveedor(proveedor);
    } else {
      await _dbHelper.updateProveedor(proveedor);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text(widget.proveedor == null
                  ? 'Proveedor creado'
                  : 'Proveedor actualizado'),
            ],
          ),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.proveedor == null ? 'Nuevo Proveedor' : 'Editar Proveedor',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Icono decorativo
            Center(
              child: Container(
                width: 100,
                height: 100,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.business_rounded,
                  size: 50,
                  color: Colors.white,
                ),
              ),
            ),

            // Nombre
            TextFormField(
              controller: _nombreController,
              decoration: InputDecoration(
                labelText: 'Nombre del proveedor',
                hintText: 'Ej: Distribuidora XYZ',
                prefixIcon: Icon(Icons.business, color: theme.colorScheme.primary),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'El nombre es requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Teléfono
            TextFormField(
              controller: _telefonoController,
              decoration: InputDecoration(
                labelText: 'Teléfono',
                hintText: 'Ej: 5551234567',
                prefixIcon: Icon(Icons.phone, color: theme.colorScheme.primary),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                ),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            // Email
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'Ej: contacto@proveedor.com',
                prefixIcon: Icon(Icons.email, color: theme.colorScheme.primary),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            // Dirección
            TextFormField(
              controller: _direccionController,
              decoration: InputDecoration(
                labelText: 'Dirección',
                hintText: 'Ej: Av. Principal #123, Col. Centro',
                prefixIcon: Icon(Icons.location_on, color: theme.colorScheme.primary),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                ),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),

            // Botón guardar
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _guardarProveedor,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.save, color: Colors.white),
                        const SizedBox(width: 12),
                        Text(
                          widget.proveedor == null ? 'Guardar' : 'Actualizar',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ComprasTab extends StatefulWidget {
  const ComprasTab({super.key});

  @override
  State<ComprasTab> createState() => _ComprasTabState();
}

class _ComprasTabState extends State<ComprasTab> {
  final _dbHelper = DatabaseHelper.instance;
  List<CompraResumen> _compras = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarCompras();
  }

  Future<void> _cargarCompras() async {
    setState(() => _isLoading = true);
    final compras = await _dbHelper.getAllCompras();
    setState(() {
      _compras = compras;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final formatoCurrency = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    final formatoFecha = DateFormat('dd/MM/yyyy HH:mm');
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_compras.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 100, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No hay compras registradas',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            Text(
              'Toca el botón (+) para agregar',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _compras.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final compra = _compras[index];
        final tituloCompra = compra.items.length == 1
            ? compra.items.first.productoNombre
            : 'Compra (${compra.items.length} productos)';
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.all(16),
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shopping_bag_rounded, color: Colors.white),
              ),
              title: Text(
                  tituloCompra,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.business, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(compra.proveedorNombre ?? "N/A"),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(formatoFecha.format(compra.fechaCompra)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        formatoCurrency.format(compra.total),
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    children: [
                      ...compra.items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${item.cantidad}x ${item.productoNombre}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              Text(
                                formatoCurrency.format(item.total),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 24),
                      _buildDetalleRow(
                        'Total',
                        formatoCurrency.format(compra.total),
                        Icons.shopping_cart,
                        theme,
                        isBold: true,
                        valueColor: Colors.green[700],
                      ),
                      if (compra.notas != null && compra.notas!.isNotEmpty) ...[
                        const Divider(height: 24),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.note, size: 18, color: theme.colorScheme.primary),
                                const SizedBox(width: 8),
                                const Text(
                                  'Notas:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Text(compra.notas!),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetalleRow(
    String label,
    String value,
    IconData icon,
    ThemeData theme, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: isBold ? 16 : 15,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            fontSize: isBold ? 18 : 15,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class FormCompraScreen extends StatefulWidget {
  const FormCompraScreen({super.key});

  @override
  State<FormCompraScreen> createState() => _FormCompraScreenState();
}

class _FormCompraScreenState extends State<FormCompraScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cantidadController = TextEditingController();
  final _precioController = TextEditingController();
  final _notasController = TextEditingController();
  final _productoBusquedaController = TextEditingController();
  final _dbHelper = DatabaseHelper.instance;

  Proveedor? _proveedorSeleccionado;
  Producto? _productoSeleccionado;
  List<Proveedor> _proveedores = [];
  List<Producto> _productos = [];
  List<Producto> _productosFiltrados = [];
  final List<_CompraItemDraft> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    final proveedores = await _dbHelper.getAllProveedores();
    final productos = await _dbHelper.getAllProductos();
    setState(() {
      _proveedores = proveedores;
      _productos = productos;
      _productosFiltrados = productos;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _precioController.dispose();
    _notasController.dispose();
    _productoBusquedaController.dispose();
    super.dispose();
  }

  double get _totalCalculado {
    return _items.fold<double>(0.0, (sum, item) => sum + item.total);
  }

  void _filtrarProductos(String query) {
    final filtro = query.trim().toLowerCase();
    setState(() {
      if (filtro.isEmpty) {
        _productosFiltrados = _productos;
      } else {
        _productosFiltrados = _productos
            .where((p) => p.nombre.toLowerCase().contains(filtro))
            .toList();
      }
      if (_productoSeleccionado != null &&
          !_productosFiltrados.contains(_productoSeleccionado)) {
        _productoSeleccionado = null;
      }
    });
  }

  void _agregarProducto() {
    if (_productoSeleccionado == null) {
      _mostrarSnackBar('Seleccione un producto', Colors.orange[600]!);
      return;
    }
    final cantidad = int.tryParse(_cantidadController.text) ?? 0;
    final precioUnitario = double.tryParse(_precioController.text) ?? 0;
    if (cantidad <= 0 || precioUnitario <= 0) {
      _mostrarSnackBar('Ingrese cantidad y precio válidos', Colors.orange[600]!);
      return;
    }

    final existenteIndex = _items.indexWhere((item) =>
        item.producto.id == _productoSeleccionado!.id &&
        item.precioUnitario == precioUnitario);

    setState(() {
      if (existenteIndex >= 0) {
        final actual = _items[existenteIndex];
        final nuevaCantidad = actual.cantidad + cantidad;
        _items[existenteIndex] = actual.copyWith(
          cantidad: nuevaCantidad,
          total: nuevaCantidad * precioUnitario,
        );
      } else {
        _items.add(_CompraItemDraft(
          producto: _productoSeleccionado!,
          cantidad: cantidad,
          precioUnitario: precioUnitario,
        ));
      }
      _productoSeleccionado = null;
      _cantidadController.clear();
      _precioController.clear();
      _productoBusquedaController.clear();
      _productosFiltrados = _productos;
    });
  }

  void _eliminarItem(int index) {
    setState(() => _items.removeAt(index));
  }

  Future<void> _guardarCompra() async {
    if (!_formKey.currentState!.validate()) return;

    if (_proveedorSeleccionado == null || _items.isEmpty) {
      _mostrarSnackBar(
        'Debe seleccionar proveedor y agregar productos',
        Colors.orange[600]!,
      );
      return;
    }

    final groupId = DateTime.now().millisecondsSinceEpoch.toString();
    for (final item in _items) {
      final compra = Compra(
        compraGroupId: groupId,
        proveedorId: _proveedorSeleccionado!.id!,
        productoId: item.producto.id!,
        cantidad: item.cantidad,
        precioUnitario: item.precioUnitario,
        total: item.total,
        notas: _notasController.text.isEmpty ? null : _notasController.text,
      );
      await _dbHelper.insertCompra(compra);
    }

    if (mounted) {
      Navigator.pop(context);
      _mostrarSnackBar('Compra registrada y stock actualizado', Colors.green[600]!);
    }
  }

  void _mostrarSnackBar(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);
    final formatoCurrency = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Registrar Compra',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Icono decorativo
            Center(
              child: Container(
                width: 100,
                height: 100,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shopping_cart_rounded,
                  size: 50,
                  color: Colors.white,
                ),
              ),
            ),

            // Proveedor
            DropdownButtonFormField<Proveedor>(
              value: _proveedorSeleccionado,
              decoration: InputDecoration(
                labelText: 'Proveedor',
                hintText: 'Seleccione un proveedor',
                prefixIcon: Icon(Icons.business, color: theme.colorScheme.primary),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                ),
              ),
              isExpanded: true,
              items: _proveedores.map((proveedor) {
                return DropdownMenuItem(
                  value: proveedor,
                  child: Text(proveedor.nombre),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _proveedorSeleccionado = value);
              },
              validator: (value) {
                if (value == null) {
                  return 'Seleccione un proveedor';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Buscar producto
            TextFormField(
              controller: _productoBusquedaController,
              decoration: InputDecoration(
                labelText: 'Buscar producto por nombre',
                hintText: 'Ej: Leche, Arroz, Atun',
                prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                ),
              ),
              onChanged: _filtrarProductos,
            ),
            const SizedBox(height: 16),

            // Producto
            DropdownButtonFormField<Producto>(
              value: _productoSeleccionado,
              decoration: InputDecoration(
                labelText: 'Producto',
                hintText: 'Seleccione un producto',
                prefixIcon: Icon(Icons.inventory, color: theme.colorScheme.primary),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                ),
              ),
              isExpanded: true,
              items: _productosFiltrados.map((producto) {
                return DropdownMenuItem(
                  value: producto,
                  child: Text(producto.nombre),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _productoSeleccionado = value);
              },
            ),
            const SizedBox(height: 16),

            // Cantidad
            TextFormField(
              controller: _cantidadController,
              decoration: InputDecoration(
                labelText: 'Cantidad',
                hintText: 'Ej: 50',
                prefixIcon: Icon(Icons.numbers, color: theme.colorScheme.primary),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                ),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Precio unitario
            TextFormField(
              controller: _precioController,
              decoration: InputDecoration(
                labelText: 'Precio unitario',
                hintText: 'Ej: 15.50',
                prefixIcon: Icon(Icons.attach_money, color: theme.colorScheme.primary),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                ),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _agregarProducto,
                icon: const Icon(Icons.add),
                label: const Text('Agregar producto'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (_items.isNotEmpty) ...[
              const Text(
                'Productos agregados',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(item.producto.nombre),
                      subtitle: Text(
                        '${item.cantidad} x ${formatoCurrency.format(item.precioUnitario)}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            formatoCurrency.format(item.total),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            onPressed: () => _eliminarItem(index),
                            icon: const Icon(Icons.close, color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],

            // Total calculado
            if (_totalCalculado > 0)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.green[50]!,
                      Colors.green[100]!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[300]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calculate, color: Colors.green[700]),
                        const SizedBox(width: 8),
                        const Text(
                          'Total:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      formatoCurrency.format(_totalCalculado),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Notas
            TextFormField(
              controller: _notasController,
              decoration: InputDecoration(
                labelText: 'Notas (opcional)',
                hintText: 'Información adicional',
                prefixIcon: Icon(Icons.note, color: theme.colorScheme.primary),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                ),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),

            // Botón guardar
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _guardarCompra,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green[600]!,
                        Colors.green[500]!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart, color: Colors.white),
                        SizedBox(width: 12),
                        Text(
                          'Registrar Compra',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompraItemDraft {
  final Producto producto;
  final int cantidad;
  final double precioUnitario;
  final double total;

  _CompraItemDraft({
    required this.producto,
    required this.cantidad,
    required this.precioUnitario,
  }) : total = cantidad * precioUnitario;

  _CompraItemDraft copyWith({
    int? cantidad,
    double? precioUnitario,
    double? total,
  }) {
    final newCantidad = cantidad ?? this.cantidad;
    final newPrecio = precioUnitario ?? this.precioUnitario;
    return _CompraItemDraft(
      producto: producto,
      cantidad: newCantidad,
      precioUnitario: newPrecio,
    );
  }
}
