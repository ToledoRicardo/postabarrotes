class ProductoVariante {
  final int? id;
  final int productoId;
  final String nombre; // Ej: "500ml", "1L", "250g"
  final double contenido; // Valor numérico del contenido
  final String unidadMedida; // ml, L, g, kg
  final double precioAdicional; // Precio adicional sobre el precio base (puede ser 0)
  final int? stockEspecifico; // Stock específico de esta variante (opcional)
  final DateTime fechaCreacion;

  ProductoVariante({
    this.id,
    required this.productoId,
    required this.nombre,
    required this.contenido,
    required this.unidadMedida,
    this.precioAdicional = 0,
    this.stockEspecifico,
    DateTime? fechaCreacion,
  }) : fechaCreacion = fechaCreacion ?? DateTime.now();

  double getPrecioTotal(double precioBase) {
    return precioBase + precioAdicional;
  }

  String getDescripcionCompleta() {
    return '$nombre ($contenido$unidadMedida)';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'producto_id': productoId,
      'nombre': nombre,
      'contenido': contenido,
      'unidad_medida': unidadMedida,
      'precio_adicional': precioAdicional,
      'stock_especifico': stockEspecifico,
      'fecha_creacion': fechaCreacion.toIso8601String(),
    };
  }

  factory ProductoVariante.fromMap(Map<String, dynamic> map) {
    return ProductoVariante(
      id: map['id'],
      productoId: map['producto_id'],
      nombre: map['nombre'],
      contenido: map['contenido'],
      unidadMedida: map['unidad_medida'],
      precioAdicional: map['precio_adicional'] ?? 0,
      stockEspecifico: map['stock_especifico'],
      fechaCreacion: DateTime.parse(map['fecha_creacion']),
    );
  }

  ProductoVariante copyWith({
    int? id,
    int? productoId,
    String? nombre,
    double? contenido,
    String? unidadMedida,
    double? precioAdicional,
    int? stockEspecifico,
    DateTime? fechaCreacion,
  }) {
    return ProductoVariante(
      id: id ?? this.id,
      productoId: productoId ?? this.productoId,
      nombre: nombre ?? this.nombre,
      contenido: contenido ?? this.contenido,
      unidadMedida: unidadMedida ?? this.unidadMedida,
      precioAdicional: precioAdicional ?? this.precioAdicional,
      stockEspecifico: stockEspecifico ?? this.stockEspecifico,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }
}
