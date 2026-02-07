import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/producto.dart';
import '../models/proveedor.dart';
import '../models/compra.dart';
import '../models/venta.dart';
import '../models/categoria.dart';
import '../models/movimiento_caja.dart';
import '../models/producto_variante.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tienda_barrotes.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 13,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  /// Crea un respaldo local de la base de datos.
  /// Si se proporciona [destDir], guarda en dicha carpeta; si no, usa la carpeta de documentos de la app.
  /// Retorna la ruta del archivo de respaldo.
  Future<String> crearBackupLocal({String? destDir}) async {
    final db = await database;
    final dbPath = await getDatabasesPath();
    final originalPath = join(dbPath, 'tienda_barrotes.db');
    
    // Cerrar la base de datos temporalmente para copiar el archivo limpio
    await db.rawQuery('PRAGMA wal_checkpoint(FULL)');
    
    late final Directory backupDir;
    if (destDir != null) {
      backupDir = Directory(destDir);
    } else {
      final docsDir = await getApplicationDocumentsDirectory();
      backupDir = Directory(join(docsDir.path, 'backups'));
    }
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final backupPath = join(backupDir.path, 'tienda_backup_$timestamp.db');
    
    final originalFile = File(originalPath);
    await originalFile.copy(backupPath);
    
    return backupPath;
  }
  
  /// Restaura la base de datos desde un archivo de respaldo.
  Future<void> restaurarBackup(String backupPath) async {
    final db = await database;
    await db.close();
    _database = null;
    
    final dbPath = await getDatabasesPath();
    final originalPath = join(dbPath, 'tienda_barrotes.db');
    
    final backupFile = File(backupPath);
    await backupFile.copy(originalPath);
    
    // Reabrir la base de datos
    _database = await _initDB('tienda_barrotes.db');
  }
  
  /// Obtiene la lista de backups disponibles.
  Future<List<FileSystemEntity>> getBackupsDisponibles() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(join(docsDir.path, 'backups'));
    if (!await backupDir.exists()) return [];
    
    final files = backupDir.listSync()
        .where((f) => f.path.endsWith('.db'))
        .toList();
    files.sort((a, b) => b.path.compareTo(a.path));
    return files;
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS categorias (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT NOT NULL,
          color TEXT,
          fecha_creacion TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS movimientos_caja (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          tipo TEXT NOT NULL,
          monto REAL NOT NULL,
          concepto TEXT,
          notas TEXT,
          fecha TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS cortes_dia (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          fecha TEXT NOT NULL,
          monto_inicial REAL NOT NULL,
          total_ventas REAL NOT NULL,
          total_ingresos REAL NOT NULL,
          total_egresos REAL NOT NULL,
          monto_esperado REAL NOT NULL,
          monto_real REAL NOT NULL,
          diferencia REAL NOT NULL,
          notas TEXT
        )
      ''');

      for (var cat in Categoria.categoriasDefault()) {
        await db.insert('categorias', cat.toMap());
      }
    }
    
    if (oldVersion < 3) {
      // Agregar categoria_parent_id a categorias para subcategorías
      await db.execute('''
        ALTER TABLE categorias ADD COLUMN categoria_parent_id INTEGER
      ''');

      // Agregar subcategoria_id y es_precio_por_peso a productos
      await db.execute('''
        ALTER TABLE productos ADD COLUMN subcategoria_id INTEGER
      ''');

      await db.execute('''
        ALTER TABLE productos ADD COLUMN es_precio_por_peso INTEGER DEFAULT 0
      ''');

      // Agregar peso_kg a detalles_venta
      await db.execute('''
        ALTER TABLE detalles_venta ADD COLUMN peso_kg REAL
      ''');
    }
    
    if (oldVersion < 4) {
      // Crear tabla de variantes de productos
      await db.execute('''
        CREATE TABLE producto_variantes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          producto_id INTEGER NOT NULL,
          nombre TEXT NOT NULL,
          contenido REAL NOT NULL,
          unidad_medida TEXT NOT NULL,
          precio_adicional REAL DEFAULT 0,
          stock_especifico INTEGER,
          fecha_creacion TEXT NOT NULL,
          FOREIGN KEY (producto_id) REFERENCES productos (id) ON DELETE CASCADE
        )
      ''');

      // Agregar variante_id a detalles_venta
      await db.execute('''
        ALTER TABLE detalles_venta ADD COLUMN variante_id INTEGER
      ''');
    }
    
    if (oldVersion < 5) {
      // Verificar e insertar categorías por defecto si no existen
      final categorias = await db.query('categorias');
      if (categorias.isEmpty) {
        for (var cat in Categoria.categoriasDefault()) {
          await db.insert('categorias', cat.toMap());
        }
      }
    }
    
    if (oldVersion < 6) {
      // Agregar nueva categoría "Frutas y Verduras" si no existe
      final frutasExiste = await db.query(
        'categorias',
        where: 'nombre = ?',
        whereArgs: ['Frutas y Verduras'],
      );
      
      if (frutasExiste.isEmpty) {
        await db.insert('categorias', {
          'nombre': 'Frutas y Verduras',
          'color': '#4CAF50',
          'fecha_creacion': DateTime.now().toIso8601String(),
        });
      }
    }
    
    if (oldVersion < 7) {
      // Agregar columna es_frecuente a productos
      await db.execute('''
        ALTER TABLE productos ADD COLUMN es_frecuente INTEGER DEFAULT 0
      ''');
      
      // Agregar columna fondo_inicial a cortes_dia
      await db.execute('''
        ALTER TABLE cortes_dia ADD COLUMN fondo_inicial REAL DEFAULT 0
      ''');
    }

    if (oldVersion < 8) {
      await db.execute('''
        ALTER TABLE compras ADD COLUMN compra_group_id TEXT
      ''');

      await db.execute('''
        UPDATE compras
        SET compra_group_id = CAST(id AS TEXT)
        WHERE compra_group_id IS NULL
      ''');

      for (var cat in Categoria.categoriasDefault()) {
        final existe = await db.query(
          'categorias',
          where: 'nombre = ?',
          whereArgs: [cat.nombre],
          limit: 1,
        );
        if (existe.isEmpty) {
          await db.insert('categorias', cat.toMap());
        }
      }
    }

    if (oldVersion < 9) {
      for (var cat in Categoria.categoriasDefault()) {
        final existe = await db.query(
          'categorias',
          where: 'nombre = ?',
          whereArgs: [cat.nombre],
          limit: 1,
        );
        if (existe.isEmpty) {
          await db.insert('categorias', cat.toMap());
        }
      }
    }

    if (oldVersion < 10) {
      for (var cat in Categoria.categoriasDefault()) {
        final existe = await db.query(
          'categorias',
          where: 'nombre = ?',
          whereArgs: [cat.nombre],
          limit: 1,
        );
        if (existe.isEmpty) {
          await db.insert('categorias', cat.toMap());
        }
      }
    }

    if (oldVersion < 11) {
      // Agregar columna marca a productos
      await db.execute('''
        ALTER TABLE productos ADD COLUMN marca TEXT
      ''');
    }

    if (oldVersion < 12) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS devoluciones (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          producto_id INTEGER NOT NULL,
          producto_nombre TEXT NOT NULL,
          cantidad INTEGER NOT NULL,
          monto REAL NOT NULL,
          concepto TEXT,
          fecha TEXT NOT NULL,
          FOREIGN KEY (producto_id) REFERENCES productos (id)
        )
      ''');
    }

    if (oldVersion < 13) {
      await db.execute('''
        ALTER TABLE productos ADD COLUMN es_stock_por_peso INTEGER DEFAULT 0
      ''');
      await db.execute('''
        ALTER TABLE productos ADD COLUMN stock_gramos REAL
      ''');

      // Agregar categoría Hielo si no existe
      final hieloExiste = await db.query(
        'categorias',
        where: 'nombre = ?',
        whereArgs: ['Hielo'],
      );
      if (hieloExiste.isEmpty) {
        await db.insert('categorias', Categoria(nombre: 'Hielo', color: '#81D4FA').toMap());
      }
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categorias (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        color TEXT,
        categoria_parent_id INTEGER,
        fecha_creacion TEXT NOT NULL,
        FOREIGN KEY (categoria_parent_id) REFERENCES categorias (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE productos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        descripcion TEXT,
        precio REAL NOT NULL,
        stock INTEGER,
        categoria_id INTEGER,
        subcategoria_id INTEGER,
        es_precio_por_peso INTEGER DEFAULT 0,
        es_frecuente INTEGER DEFAULT 0,
        es_stock_por_peso INTEGER DEFAULT 0,
        stock_gramos REAL,
        marca TEXT,
        fecha_creacion TEXT NOT NULL,
        FOREIGN KEY (categoria_id) REFERENCES categorias (id),
        FOREIGN KEY (subcategoria_id) REFERENCES categorias (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE proveedores (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        telefono TEXT,
        email TEXT,
        direccion TEXT,
        fecha_creacion TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE compras (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        compra_group_id TEXT,
        proveedor_id INTEGER NOT NULL,
        producto_id INTEGER NOT NULL,
        cantidad INTEGER NOT NULL,
        precio_unitario REAL NOT NULL,
        total REAL NOT NULL,
        fecha_compra TEXT NOT NULL,
        notas TEXT,
        FOREIGN KEY (proveedor_id) REFERENCES proveedores (id),
        FOREIGN KEY (producto_id) REFERENCES productos (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE ventas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        total REAL NOT NULL,
        monto_pagado REAL NOT NULL,
        cambio REAL NOT NULL,
        fecha_venta TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE detalles_venta (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        venta_id INTEGER NOT NULL,
        producto_id INTEGER NOT NULL,
        producto_nombre TEXT NOT NULL,
        cantidad INTEGER NOT NULL,
        precio_unitario REAL NOT NULL,
        subtotal REAL NOT NULL,
        peso_kg REAL,
        variante_id INTEGER,
        FOREIGN KEY (venta_id) REFERENCES ventas (id),
        FOREIGN KEY (producto_id) REFERENCES productos (id),
        FOREIGN KEY (variante_id) REFERENCES producto_variantes (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE producto_variantes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        producto_id INTEGER NOT NULL,
        nombre TEXT NOT NULL,
        contenido REAL NOT NULL,
        unidad_medida TEXT NOT NULL,
        precio_adicional REAL DEFAULT 0,
        stock_especifico INTEGER,
        fecha_creacion TEXT NOT NULL,
        FOREIGN KEY (producto_id) REFERENCES productos (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE movimientos_caja (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tipo TEXT NOT NULL,
        monto REAL NOT NULL,
        concepto TEXT,
        notas TEXT,
        fecha TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE cortes_dia (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha TEXT NOT NULL,
        monto_inicial REAL NOT NULL,
        total_ventas REAL NOT NULL,
        total_ingresos REAL NOT NULL,
        total_egresos REAL NOT NULL,
        monto_esperado REAL NOT NULL,
        monto_real REAL NOT NULL,
        diferencia REAL NOT NULL,
        notas TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE devoluciones (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        producto_id INTEGER NOT NULL,
        producto_nombre TEXT NOT NULL,
        cantidad INTEGER NOT NULL,
        monto REAL NOT NULL,
        concepto TEXT,
        fecha TEXT NOT NULL,
        FOREIGN KEY (producto_id) REFERENCES productos (id)
      )
    ''');

    for (var cat in Categoria.categoriasDefault()) {
      await db.insert('categorias', cat.toMap());
    }
  }

  // CATEGORÍAS
  Future<int> insertCategoria(Categoria categoria) async {
    final db = await database;
    return await db.insert('categorias', categoria.toMap());
  }

  Future<List<Categoria>> getAllCategorias() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT c.*, cp.nombre as categoria_padre_nombre
      FROM categorias c
      LEFT JOIN categorias cp ON c.categoria_parent_id = cp.id
      ORDER BY c.nombre ASC
    ''');
    return result.map((map) => Categoria.fromMap(map)).toList();
  }

  Future<List<Categoria>> getCategoriasBase() async {
    final db = await database;
    final result = await db.query(
      'categorias',
      where: 'categoria_parent_id IS NULL',
      orderBy: 'nombre ASC',
    );
    return result.map((map) => Categoria.fromMap(map)).toList();
  }

  Future<List<Categoria>> getSubcategorias(int categoriaParentId) async {
    final db = await database;
    final result = await db.query(
      'categorias',
      where: 'categoria_parent_id = ?',
      whereArgs: [categoriaParentId],
      orderBy: 'nombre ASC',
    );
    return result.map((map) => Categoria.fromMap(map)).toList();
  }

  Future<List<Categoria>> getAllSubcategorias() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT c.*, cp.nombre as categoria_padre_nombre
      FROM categorias c
      LEFT JOIN categorias cp ON c.categoria_parent_id = cp.id
      WHERE c.categoria_parent_id IS NOT NULL
      ORDER BY cp.nombre ASC, c.nombre ASC
    ''');
    return result.map((map) => Categoria.fromMap(map)).toList();
  }

  Future<int> deleteCategoria(int id) async {
    final db = await database;
    return await db.delete('categorias', where: 'id = ?', whereArgs: [id]);
  }

  // PRODUCTOS
  Future<int> insertProducto(Producto producto) async {
    final db = await database;
    return await db.insert('productos', producto.toMap());
  }

  Future<List<Producto>> getAllProductos() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT p.*, 
             c.nombre as categoria_nombre,
             sc.nombre as subcategoria_nombre
      FROM productos p
      LEFT JOIN categorias c ON p.categoria_id = c.id
      LEFT JOIN categorias sc ON p.subcategoria_id = sc.id
      ORDER BY p.nombre ASC
    ''');
    return result.map((map) => Producto.fromMap(map)).toList();
  }

  Future<List<Producto>> getProductosPorCategoria(int categoriaId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT p.*, 
             c.nombre as categoria_nombre,
             sc.nombre as subcategoria_nombre
      FROM productos p
      LEFT JOIN categorias c ON p.categoria_id = c.id
      LEFT JOIN categorias sc ON p.subcategoria_id = sc.id
      WHERE p.categoria_id = ?
      ORDER BY p.nombre ASC
    ''', [categoriaId]);
    return result.map((map) => Producto.fromMap(map)).toList();
  }

  Future<List<Producto>> getProductosPorSubcategoria(int subcategoriaId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT p.*, 
             c.nombre as categoria_nombre,
             sc.nombre as subcategoria_nombre
      FROM productos p
      LEFT JOIN categorias c ON p.categoria_id = c.id
      LEFT JOIN categorias sc ON p.subcategoria_id = sc.id
      WHERE p.subcategoria_id = ?
      ORDER BY p.nombre ASC
    ''', [subcategoriaId]);
    return result.map((map) => Producto.fromMap(map)).toList();
  }

  Future<List<Producto>> getProductosPorCategoriaYSubcategoria(
      int categoriaId, int? subcategoriaId) async {
    final db = await database;
    
    String whereClause;
    List<dynamic> whereArgs;
    
    if (subcategoriaId != null) {
      whereClause = 'p.categoria_id = ? AND p.subcategoria_id = ?';
      whereArgs = [categoriaId, subcategoriaId];
    } else {
      whereClause = 'p.categoria_id = ?';
      whereArgs = [categoriaId];
    }
    
    final result = await db.rawQuery('''
      SELECT p.*, 
             c.nombre as categoria_nombre,
             sc.nombre as subcategoria_nombre
      FROM productos p
      LEFT JOIN categorias c ON p.categoria_id = c.id
      LEFT JOIN categorias sc ON p.subcategoria_id = sc.id
      WHERE $whereClause
      ORDER BY p.nombre ASC
    ''', whereArgs);
    return result.map((map) => Producto.fromMap(map)).toList();
  }

  Future<Producto?> getProducto(int id) async {
    final db = await database;
    final result = await db.query(
      'productos',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return Producto.fromMap(result.first);
    }
    return null;
  }

  Future<int> updateProducto(Producto producto) async {
    final db = await database;
    return await db.update(
      'productos',
      producto.toMap(),
      where: 'id = ?',
      whereArgs: [producto.id],
    );
  }

  Future<int> deleteProducto(int id) async {
    final db = await database;
    return await db.delete(
      'productos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateProductoStock(int id, int nuevoStock) async {
    final db = await database;
    return await db.update(
      'productos',
      {'stock': nuevoStock},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateProductoStockGramos(int id, double gramos) async {
    final db = await database;
    return await db.update(
      'productos',
      {'stock_gramos': gramos},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateProductoMarca(List<int> ids, String? marca) async {
    final db = await database;
    for (final id in ids) {
      await db.update(
        'productos',
        {'marca': marca},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<void> updateProductoStockBatch(Map<int, int> stockMap) async {
    final db = await database;
    for (final entry in stockMap.entries) {
      await db.update(
        'productos',
        {'stock': entry.value},
        where: 'id = ?',
        whereArgs: [entry.key],
      );
    }
  }

  // PROVEEDORES
  Future<int> insertProveedor(Proveedor proveedor) async {
    final db = await database;
    return await db.insert('proveedores', proveedor.toMap());
  }

  Future<List<Proveedor>> getAllProveedores() async {
    final db = await database;
    final result = await db.query('proveedores', orderBy: 'nombre ASC');
    return result.map((map) => Proveedor.fromMap(map)).toList();
  }

  Future<int> updateProveedor(Proveedor proveedor) async {
    final db = await database;
    return await db.update(
      'proveedores',
      proveedor.toMap(),
      where: 'id = ?',
      whereArgs: [proveedor.id],
    );
  }

  Future<int> deleteProveedor(int id) async {
    final db = await database;
    return await db.delete(
      'proveedores',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // COMPRAS
  Future<int> insertCompra(Compra compra) async {
    final db = await database;
    final compraId = await db.insert('compras', compra.toMap());
    
    final producto = await getProducto(compra.productoId);
    if (producto != null && producto.stock != null) {
      await updateProductoStock(
        compra.productoId,
        producto.stock! + compra.cantidad,
      );
    } else if (producto != null) {
      await updateProductoStock(compra.productoId, compra.cantidad);
    }
    
    return compraId;
  }

  Future<List<CompraResumen>> getAllCompras() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT
        COALESCE(c.compra_group_id, CAST(c.id AS TEXT)) as compra_group_id,
        c.proveedor_id as proveedor_id,
        pr.nombre as proveedor_nombre,
        MAX(c.fecha_compra) as fecha_compra,
        SUM(c.total) as total,
        MAX(c.notas) as notas
      FROM compras c
      LEFT JOIN proveedores pr ON c.proveedor_id = pr.id
      GROUP BY COALESCE(c.compra_group_id, CAST(c.id AS TEXT)), c.proveedor_id
      ORDER BY fecha_compra DESC
    ''');

    List<CompraResumen> compras = [];
    for (final map in result) {
      final groupId = map['compra_group_id'] as String;
      final items = await _getCompraItemsPorGrupo(groupId);
      compras.add(CompraResumen(
        groupId: groupId,
        proveedorId: map['proveedor_id'] as int,
        proveedorNombre: map['proveedor_nombre'] as String?,
        fechaCompra: DateTime.parse(map['fecha_compra'] as String),
        total: (map['total'] as num).toDouble(),
        notas: map['notas'] as String?,
        items: items,
      ));
    }

    return compras;
  }

  Future<List<CompraItem>> _getCompraItemsPorGrupo(String groupId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT c.*, p.nombre as producto_nombre
      FROM compras c
      LEFT JOIN productos p ON c.producto_id = p.id
      WHERE COALESCE(c.compra_group_id, CAST(c.id AS TEXT)) = ?
      ORDER BY c.id ASC
    ''', [groupId]);
    return result.map((map) => CompraItem.fromMap(map)).toList();
  }

  Future<void> deleteCompraGroup(String groupId) async {
    final db = await database;
    
    // Obtener items de la compra para revertir el stock
    final items = await db.rawQuery('''
      SELECT producto_id, cantidad FROM compras
      WHERE COALESCE(compra_group_id, CAST(id AS TEXT)) = ?
    ''', [groupId]);
    
    // Revertir stock de cada producto
    for (final item in items) {
      final productoId = (item['producto_id'] as num).toInt();
      final cantidad = (item['cantidad'] as num).toInt();
      final producto = await getProducto(productoId);
      if (producto != null && producto.stock != null) {
        final nuevoStock = producto.stock! - cantidad;
        await updateProductoStock(productoId, nuevoStock < 0 ? 0 : nuevoStock);
      }
    }
    
    // Eliminar los registros de compra
    await db.delete(
      'compras',
      where: 'COALESCE(compra_group_id, CAST(id AS TEXT)) = ?',
      whereArgs: [groupId],
    );
  }

  // VENTAS
  Future<int> insertVenta(Venta venta) async {
    final db = await database;
    
    final ventaId = await db.insert('ventas', venta.toMap());
    
    for (var detalle in venta.detalles) {
      final detalleMap = detalle.toMap();
      detalleMap['venta_id'] = ventaId;
      await db.insert('detalles_venta', detalleMap);
      
      final producto = await getProducto(detalle.productoId);
      if (producto != null && producto.stock != null) {
        await updateProductoStock(
          detalle.productoId,
          producto.stock! - detalle.cantidad,
        );
      }
    }
    
    await insertMovimientoCaja(MovimientoCaja(
      tipo: 'venta',
      monto: venta.total,
      concepto: 'Venta #$ventaId',
    ));
    
    return ventaId;
  }

  Future<List<Venta>> getVentasPorFecha(DateTime fecha) async {
    final db = await database;
    final inicioDia = DateTime(fecha.year, fecha.month, fecha.day);
    final finDia = inicioDia.add(const Duration(days: 1));
    
    final result = await db.query(
      'ventas',
      where: 'fecha_venta >= ? AND fecha_venta < ?',
      whereArgs: [inicioDia.toIso8601String(), finDia.toIso8601String()],
      orderBy: 'fecha_venta DESC',
    );
    
    List<Venta> ventas = [];
    for (var map in result) {
      final venta = Venta.fromMap(map);
      final detalles = await getDetallesVenta(venta.id!);
      ventas.add(Venta(
        id: venta.id,
        total: venta.total,
        montoPagado: venta.montoPagado,
        cambio: venta.cambio,
        fechaVenta: venta.fechaVenta,
        detalles: detalles,
      ));
    }
    
    return ventas;
  }

  Future<List<Venta>> getAllVentas() async {
    final db = await database;
    final result = await db.query('ventas', orderBy: 'fecha_venta DESC');
    
    List<Venta> ventas = [];
    for (var map in result) {
      final venta = Venta.fromMap(map);
      final detalles = await getDetallesVenta(venta.id!);
      ventas.add(Venta(
        id: venta.id,
        total: venta.total,
        montoPagado: venta.montoPagado,
        cambio: venta.cambio,
        fechaVenta: venta.fechaVenta,
        detalles: detalles,
      ));
    }
    
    return ventas;
  }

  Future<List<DetalleVenta>> getDetallesVenta(int ventaId) async {
    final db = await database;
    final result = await db.query(
      'detalles_venta',
      where: 'venta_id = ?',
      whereArgs: [ventaId],
    );
    return result.map((map) => DetalleVenta.fromMap(map)).toList();
  }

  Future<void> deleteVenta(int ventaId) async {
    final db = await database;
    final detalles = await getDetallesVenta(ventaId);

    for (final detalle in detalles) {
      final producto = await getProducto(detalle.productoId);
      if (producto != null && producto.stock != null) {
        await updateProductoStock(
          detalle.productoId,
          producto.stock! + detalle.cantidad,
        );
      }
    }

    await db.delete('detalles_venta', where: 'venta_id = ?', whereArgs: [ventaId]);
    await db.delete('ventas', where: 'id = ?', whereArgs: [ventaId]);
    await db.delete(
      'movimientos_caja',
      where: 'tipo = ? AND concepto = ?',
      whereArgs: ['venta', 'Venta #$ventaId'],
    );
  }

  // MOVIMIENTOS DE CAJA
  Future<int> insertMovimientoCaja(MovimientoCaja movimiento) async {
    final db = await database;
    return await db.insert('movimientos_caja', movimiento.toMap());
  }

  Future<List<MovimientoCaja>> getMovimientosPorFecha(DateTime fecha) async {
    final db = await database;
    final inicioDia = DateTime(fecha.year, fecha.month, fecha.day);
    final finDia = inicioDia.add(const Duration(days: 1));
    
    final result = await db.query(
      'movimientos_caja',
      where: 'fecha >= ? AND fecha < ?',
      whereArgs: [inicioDia.toIso8601String(), finDia.toIso8601String()],
      orderBy: 'fecha DESC',
    );
    
    return result.map((map) => MovimientoCaja.fromMap(map)).toList();
  }

  Future<double> getTotalVentasDia(DateTime fecha) async {
    final db = await database;
    final inicioDia = DateTime(fecha.year, fecha.month, fecha.day);
    final finDia = inicioDia.add(const Duration(days: 1));
    
    final result = await db.rawQuery('''
      SELECT SUM(total) as total
      FROM ventas
      WHERE fecha_venta >= ? AND fecha_venta < ?
    ''', [inicioDia.toIso8601String(), finDia.toIso8601String()]);
    
    return result.first['total'] as double? ?? 0.0;
  }

  Future<double> getTotalIngresosDia(DateTime fecha) async {
    final movimientos = await getMovimientosPorFecha(fecha);
    return movimientos
        .where((m) => m.tipo == 'ingreso')
        .fold<double>(0.0, (sum, m) => sum + m.monto);
  }

  Future<double> getTotalEgresosDia(DateTime fecha) async {
    final movimientos = await getMovimientosPorFecha(fecha);
    return movimientos
        .where((m) => m.tipo == 'egreso')
        .fold<double>(0.0, (sum, m) => sum + m.monto);
  }

  // FONDO DEL DÍA
  Future<int> guardarFondoDelDia(DateTime fecha, double monto) async {
    final db = await database;
    return await db.insert('movimientos_caja', {
      'tipo': 'fondo_inicial',
      'monto': monto,
      'concepto': 'Fondo inicial del día',
      'fecha': fecha.toIso8601String(),
    });
  }

  Future<double?> obtenerFondoDelDia(DateTime fecha) async {
    final db = await database;
    final inicioDia = DateTime(fecha.year, fecha.month, fecha.day);
    final finDia = inicioDia.add(const Duration(days: 1));
    
    final result = await db.query(
      'movimientos_caja',
      where: 'tipo = ? AND fecha >= ? AND fecha < ?',
      whereArgs: ['fondo_inicial', inicioDia.toIso8601String(), finDia.toIso8601String()],
      limit: 1,
    );
    
    if (result.isNotEmpty) {
      return result.first['monto'] as double?;
    }
    return null;
  }

  Future<int> actualizarFondoDelDia(DateTime fecha, double nuevoMonto) async {
    final db = await database;
    final inicioDia = DateTime(fecha.year, fecha.month, fecha.day);
    final finDia = inicioDia.add(const Duration(days: 1));
    
    return await db.update(
      'movimientos_caja',
      {'monto': nuevoMonto},
      where: 'tipo = ? AND fecha >= ? AND fecha < ?',
      whereArgs: ['fondo_inicial', inicioDia.toIso8601String(), finDia.toIso8601String()],
    );
  }

  // CORTES DEL DÍA
  Future<int> insertCorteDia(CorteDia corte) async {
    final db = await database;
    return await db.insert('cortes_dia', corte.toMap());
  }

  Future<List<CorteDia>> getAllCortes() async {
    final db = await database;
    final result = await db.query('cortes_dia', orderBy: 'fecha DESC');
    return result.map((map) => CorteDia.fromMap(map)).toList();
  }

  Future<CorteDia?> getCortePorFecha(DateTime fecha) async {
    final db = await database;
    final inicioDia = DateTime(fecha.year, fecha.month, fecha.day);
    final finDia = inicioDia.add(const Duration(days: 1));
    
    final result = await db.query(
      'cortes_dia',
      where: 'fecha >= ? AND fecha < ?',
      whereArgs: [inicioDia.toIso8601String(), finDia.toIso8601String()],
    );
    
    if (result.isNotEmpty) {
      return CorteDia.fromMap(result.first);
    }
    return null;
  }

  Future<int> deleteCorteDia(int id) async {
    final db = await database;
    return await db.delete('cortes_dia', where: 'id = ?', whereArgs: [id]);
  }

  // VARIANTES DE PRODUCTOS
  Future<int> insertProductoVariante(ProductoVariante variante) async {
    final db = await database;
    return await db.insert('producto_variantes', variante.toMap());
  }

  Future<List<ProductoVariante>> getVariantesPorProducto(int productoId) async {
    final db = await database;
    final result = await db.query(
      'producto_variantes',
      where: 'producto_id = ?',
      whereArgs: [productoId],
      orderBy: 'contenido ASC',
    );
    return result.map((map) => ProductoVariante.fromMap(map)).toList();
  }

  Future<ProductoVariante?> getVariante(int varianteId) async {
    final db = await database;
    final result = await db.query(
      'producto_variantes',
      where: 'id = ?',
      whereArgs: [varianteId],
    );
    
    if (result.isNotEmpty) {
      return ProductoVariante.fromMap(result.first);
    }
    return null;
  }

  Future<int> updateProductoVariante(ProductoVariante variante) async {
    final db = await database;
    return await db.update(
      'producto_variantes',
      variante.toMap(),
      where: 'id = ?',
      whereArgs: [variante.id],
    );
  }

  Future<int> deleteProductoVariante(int id) async {
    final db = await database;
    return await db.delete(
      'producto_variantes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // DEVOLUCIONES
  Future<int> insertDevolucion({
    required int productoId,
    required String productoNombre,
    required int cantidad,
    required double monto,
    String? concepto,
  }) async {
    final db = await database;
    final fecha = DateTime.now().toIso8601String();

    final devId = await db.insert('devoluciones', {
      'producto_id': productoId,
      'producto_nombre': productoNombre,
      'cantidad': cantidad,
      'monto': monto,
      'concepto': concepto,
      'fecha': fecha,
    });

    // Registrar como egreso en caja (monto negativo conceptualmente)
    await insertMovimientoCaja(MovimientoCaja(
      tipo: 'egreso',
      monto: monto,
      concepto: 'Devolución: $productoNombre${concepto != null && concepto.isNotEmpty ? ' - $concepto' : ''}',
    ));

    return devId;
  }

  Future<List<Map<String, dynamic>>> getDevolucionesPorFecha(DateTime fecha) async {
    final db = await database;
    final inicioDia = DateTime(fecha.year, fecha.month, fecha.day);
    final finDia = inicioDia.add(const Duration(days: 1));

    final result = await db.query(
      'devoluciones',
      where: 'fecha >= ? AND fecha < ?',
      whereArgs: [inicioDia.toIso8601String(), finDia.toIso8601String()],
      orderBy: 'fecha DESC',
    );
    return result;
  }

  Future<double> getTotalDevolucionesDia(DateTime fecha) async {
    final db = await database;
    final inicioDia = DateTime(fecha.year, fecha.month, fecha.day);
    final finDia = inicioDia.add(const Duration(days: 1));

    final result = await db.rawQuery('''
      SELECT SUM(monto) as total
      FROM devoluciones
      WHERE fecha >= ? AND fecha < ?
    ''', [inicioDia.toIso8601String(), finDia.toIso8601String()]);

    return result.first['total'] as double? ?? 0.0;
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
