class Compra {
  final int? id;
  final String? compraGroupId;
  final int proveedorId;
  final int productoId;
  final int cantidad;
  final double precioUnitario;
  final double total;
  final DateTime fechaCompra;
  final String? notas;

  // Campos relacionados para mostrar
  String? proveedorNombre;
  String? productoNombre;

  Compra({
    this.id,
    this.compraGroupId,
    required this.proveedorId,
    required this.productoId,
    required this.cantidad,
    required this.precioUnitario,
    required this.total,
    DateTime? fechaCompra,
    this.notas,
    this.proveedorNombre,
    this.productoNombre,
  }) : fechaCompra = fechaCompra ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'compra_group_id': compraGroupId,
      'proveedor_id': proveedorId,
      'producto_id': productoId,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      'total': total,
      'fecha_compra': fechaCompra.toIso8601String(),
      'notas': notas,
    };
  }

  factory Compra.fromMap(Map<String, dynamic> map) {
    return Compra(
      id: map['id'],
      compraGroupId: map['compra_group_id'],
      proveedorId: map['proveedor_id'],
      productoId: map['producto_id'],
      cantidad: map['cantidad'],
      precioUnitario: map['precio_unitario'],
      total: map['total'],
      fechaCompra: DateTime.parse(map['fecha_compra']),
      notas: map['notas'],
      proveedorNombre: map['proveedor_nombre'],
      productoNombre: map['producto_nombre'],
    );
  }
}

class CompraItem {
  final int productoId;
  final String productoNombre;
  final int cantidad;
  final double precioUnitario;
  final double total;

  CompraItem({
    required this.productoId,
    required this.productoNombre,
    required this.cantidad,
    required this.precioUnitario,
    required this.total,
  });

  factory CompraItem.fromMap(Map<String, dynamic> map) {
    return CompraItem(
      productoId: map['producto_id'],
      productoNombre: map['producto_nombre'] ?? 'Producto desconocido',
      cantidad: map['cantidad'],
      precioUnitario: map['precio_unitario'],
      total: map['total'],
    );
  }
}

class CompraResumen {
  final String groupId;
  final int proveedorId;
  final String? proveedorNombre;
  final DateTime fechaCompra;
  final double total;
  final String? notas;
  final List<CompraItem> items;

  CompraResumen({
    required this.groupId,
    required this.proveedorId,
    required this.fechaCompra,
    required this.total,
    this.proveedorNombre,
    this.notas,
    this.items = const [],
  });
}
