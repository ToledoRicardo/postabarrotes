class Categoria {
  final int? id;
  final String nombre;
  final String? color;
  final int? categoriaParentId; // Para subcategorías
  final DateTime fechaCreacion;

  // Campo relacional
  String? categoriaPadreNombre;

  Categoria({
    this.id,
    required this.nombre,
    this.color,
    this.categoriaParentId,
    DateTime? fechaCreacion,
    this.categoriaPadreNombre,
  }) : fechaCreacion = fechaCreacion ?? DateTime.now();

  // Helper para saber si es subcategoría
  bool get esSubcategoria => categoriaParentId != null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'color': color,
      'categoria_parent_id': categoriaParentId,
      'fecha_creacion': fechaCreacion.toIso8601String(),
    };
  }

  factory Categoria.fromMap(Map<String, dynamic> map) {
    return Categoria(
      id: map['id'],
      nombre: map['nombre'],
      color: map['color'],
      categoriaParentId: map['categoria_parent_id'],
      fechaCreacion: DateTime.parse(map['fecha_creacion']),
      categoriaPadreNombre: map['categoria_padre_nombre'],
    );
  }

  static List<Categoria> categoriasDefault() {
    return [
      Categoria(nombre: 'Bebidas', color: '#4CAF50'),
      Categoria(nombre: 'Papitas', color: '#FF9800'),
      Categoria(nombre: 'Despensa', color: '#2196F3'),
      Categoria(nombre: 'Lácteos', color: '#9C27B0'),
      Categoria(nombre: 'Cocina', color: '#607D8B'),
      Categoria(nombre: 'Carne procesada', color: '#6D4C41'),
      Categoria(nombre: 'Harinas', color: '#795548'),
      Categoria(nombre: 'Enlatado', color: '#009688'),
      Categoria(nombre: 'Refrescos', color: '#F44336'),
      Categoria(nombre: 'Aguas', color: '#00BCD4'),
      Categoria(nombre: 'Dulces', color: '#E91E63'),
      Categoria(nombre: 'Pan y Tortillas', color: '#FFB74D'),
      Categoria(nombre: 'Higiene personal', color: '#8BC34A'),
      Categoria(nombre: 'Limpieza', color: '#00ACC1'),
      Categoria(nombre: 'Cigarros', color: '#607D8B'),
      Categoria(nombre: 'GAMESA', color: '#795548'),
      Categoria(nombre: 'BIMBO', color: '#FFC107'),
      Categoria(nombre: 'Frutas y Verduras', color: '#4CAF50'),
    ];
  }
}
