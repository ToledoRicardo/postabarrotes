class Venta {
  final int? id;
  final double total;
  final double montoPagado;
  final double cambio;
  final DateTime fechaVenta;
  final List<DetalleVenta> detalles;

  Venta({
    this.id,
    required this.total,
    required this.montoPagado,
    required this.cambio,
    DateTime? fechaVenta,
    this.detalles = const [],
  }) : fechaVenta = fechaVenta ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'total': total,
      'monto_pagado': montoPagado,
      'cambio': cambio,
      'fecha_venta': fechaVenta.toIso8601String(),
    };
  }

  factory Venta.fromMap(Map<String, dynamic> map) {
    return Venta(
      id: map['id'],
      total: map['total'],
      montoPagado: map['monto_pagado'],
      cambio: map['cambio'],
      fechaVenta: DateTime.parse(map['fecha_venta']),
    );
  }
}

class DetalleVenta {
  final int? id;
  final int? ventaId;
  final int productoId;
  final String productoNombre;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;
  final double? pesoKg; // Para productos vendidos por peso
  final int? varianteId; // Para productos con variantes

  DetalleVenta({
    this.id,
    this.ventaId,
    required this.productoId,
    required this.productoNombre,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
    this.pesoKg,
    this.varianteId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'venta_id': ventaId,
      'producto_id': productoId,
      'producto_nombre': productoNombre,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      'subtotal': subtotal,
      'peso_kg': pesoKg,
      'variante_id': varianteId,
    };
  }

  factory DetalleVenta.fromMap(Map<String, dynamic> map) {
    return DetalleVenta(
      id: map['id'],
      ventaId: map['venta_id'],
      productoId: map['producto_id'],
      productoNombre: map['producto_nombre'],
      cantidad: map['cantidad'],
      precioUnitario: map['precio_unitario'],
      subtotal: map['subtotal'],
      pesoKg: map['peso_kg'],
      varianteId: map['variante_id'],
    );
  }
}
