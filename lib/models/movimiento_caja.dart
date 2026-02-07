class MovimientoCaja {
  final int? id;
  final String tipo; // 'ingreso', 'egreso', 'venta'
  final double monto;
  final String? concepto;
  final String? notas;
  final DateTime fecha;

  MovimientoCaja({
    this.id,
    required this.tipo,
    required this.monto,
    this.concepto,
    this.notas,
    DateTime? fecha,
  }) : fecha = fecha ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tipo': tipo,
      'monto': monto,
      'concepto': concepto,
      'notas': notas,
      'fecha': fecha.toIso8601String(),
    };
  }

  factory MovimientoCaja.fromMap(Map<String, dynamic> map) {
    return MovimientoCaja(
      id: map['id'],
      tipo: map['tipo'],
      monto: map['monto'],
      concepto: map['concepto'],
      notas: map['notas'],
      fecha: DateTime.parse(map['fecha']),
    );
  }
}

class CorteDia {
  final int? id;
  final DateTime fecha;
  final double montoInicial;
  final double totalVentas;
  final double totalIngresos;
  final double totalEgresos;
  final double montoEsperado;
  final double montoReal;
  final double diferencia;
  final String? notas;

  CorteDia({
    this.id,
    required this.fecha,
    required this.montoInicial,
    required this.totalVentas,
    required this.totalIngresos,
    required this.totalEgresos,
    required this.montoEsperado,
    required this.montoReal,
    required this.diferencia,
    this.notas,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fecha': fecha.toIso8601String(),
      'monto_inicial': montoInicial,
      'total_ventas': totalVentas,
      'total_ingresos': totalIngresos,
      'total_egresos': totalEgresos,
      'monto_esperado': montoEsperado,
      'monto_real': montoReal,
      'diferencia': diferencia,
      'notas': notas,
    };
  }

  factory CorteDia.fromMap(Map<String, dynamic> map) {
    return CorteDia(
      id: map['id'],
      fecha: DateTime.parse(map['fecha']),
      montoInicial: map['monto_inicial'],
      totalVentas: map['total_ventas'],
      totalIngresos: map['total_ingresos'],
      totalEgresos: map['total_egresos'],
      montoEsperado: map['monto_esperado'],
      montoReal: map['monto_real'],
      diferencia: map['diferencia'],
      notas: map['notas'],
    );
  }
}
