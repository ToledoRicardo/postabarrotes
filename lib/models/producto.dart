class Producto {
  final int? id;
  final String nombre;
  final String? descripcion;
  final double precio;
  final int? stock;
  final int? categoriaId;
  final int? subcategoriaId; // Para subcategorías
  final bool esPrecioPorPeso; // true si el precio es por kg
  final bool esFrecuente; // true si es producto frecuente
  final DateTime fechaCreacion;

  // Campos relacionales
  String? categoriaNombre;
  String? subcategoriaNombre;

  Producto({
    this.id,
    required this.nombre,
    this.descripcion,
    required this.precio,
    this.stock,
    this.categoriaId,
    this.subcategoriaId,
    this.esPrecioPorPeso = false,
    this.esFrecuente = false,
    DateTime? fechaCreacion,
    this.categoriaNombre,
    this.subcategoriaNombre,
  }) : fechaCreacion = fechaCreacion ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'precio': precio,
      'stock': stock,
      'categoria_id': categoriaId,
      'subcategoria_id': subcategoriaId,
      'es_precio_por_peso': esPrecioPorPeso ? 1 : 0,
      'es_frecuente': esFrecuente ? 1 : 0,
      'fecha_creacion': fechaCreacion.toIso8601String(),
    };
  }

  factory Producto.fromMap(Map<String, dynamic> map) {
    return Producto(
      id: map['id'],
      nombre: map['nombre'],
      descripcion: map['descripcion'],
      precio: map['precio'],
      stock: map['stock'],
      categoriaId: map['categoria_id'],
      subcategoriaId: map['subcategoria_id'],
      esPrecioPorPeso: map['es_precio_por_peso'] == 1,
      esFrecuente: map['es_frecuente'] == 1,
      fechaCreacion: DateTime.parse(map['fecha_creacion']),
      categoriaNombre: map['categoria_nombre'],
      subcategoriaNombre: map['subcategoria_nombre'],
    );
  }

  Producto copyWith({
    int? id,
    String? nombre,
    String? descripcion,
    double? precio,
    int? stock,
    int? categoriaId,
    int? subcategoriaId,
    bool? esPrecioPorPeso,
    bool? esFrecuente,
    DateTime? fechaCreacion,
    String? categoriaNombre,
    String? subcategoriaNombre,
  }) {
    return Producto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      precio: precio ?? this.precio,
      stock: stock ?? this.stock,
      categoriaId: categoriaId ?? this.categoriaId,
      subcategoriaId: subcategoriaId ?? this.subcategoriaId,
      esPrecioPorPeso: esPrecioPorPeso ?? this.esPrecioPorPeso,
      esFrecuente: esFrecuente ?? this.esFrecuente,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      categoriaNombre: categoriaNombre ?? this.categoriaNombre,
      subcategoriaNombre: subcategoriaNombre ?? this.subcategoriaNombre,
    );
  }
}
