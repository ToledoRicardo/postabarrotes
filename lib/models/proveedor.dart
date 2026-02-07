class Proveedor {
  final int? id;
  final String nombre;
  final String? telefono;
  final String? email;
  final String? direccion;
  final DateTime fechaCreacion;

  Proveedor({
    this.id,
    required this.nombre,
    this.telefono,
    this.email,
    this.direccion,
    DateTime? fechaCreacion,
  }) : fechaCreacion = fechaCreacion ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'telefono': telefono,
      'email': email,
      'direccion': direccion,
      'fecha_creacion': fechaCreacion.toIso8601String(),
    };
  }

  factory Proveedor.fromMap(Map<String, dynamic> map) {
    return Proveedor(
      id: map['id'],
      nombre: map['nombre'],
      telefono: map['telefono'],
      email: map['email'],
      direccion: map['direccion'],
      fechaCreacion: DateTime.parse(map['fecha_creacion']),
    );
  }
}
