# Tienda de Abarrotes - Sistema Punto de Venta

Aplicación móvil completa para gestión de punto de venta en tiendas de abarrotes.

## Características

### 🛒 Punto de Venta
- Interfaz intuitiva con grid de productos
- Carrito de compras con ajuste de cantidades
- Sistema de pago con botones de billetes mexicanos ($20, $50, $100, $200, $500, $1000)
- Cálculo automático de cambio
- Entrada manual de monto de pago
- Registro de ventas con actualización automática de inventario

### 📦 Gestión de Productos
- Agregar, editar y eliminar productos
- Control de stock con alertas de bajo inventario
- Precio de venta
- Descripción y código de barras
- Actualización automática de stock en ventas y compras

### 🏢 Gestión de Proveedores
- Registro de proveedores con información de contacto
- Historial de compras por proveedor
- Seguimiento de precios de compra

### 📊 Registro de Compras
- Registro de compras a proveedores
- Precio unitario y cantidad
- Notas sobre la compra
- Actualización automática de inventario al registrar compra

## Tecnologías Utilizadas

- **Flutter**: Framework de desarrollo
- **SQLite (sqflite)**: Base de datos local
- **Provider**: Gestión de estado (preparado para uso)
- **intl**: Formateo de moneda y fechas

## Instalación y Uso

### Requisitos Previos
- Flutter SDK instalado
- Android Studio o VS Code con extensiones de Flutter
- Dispositivo Android/iOS o emulador

### Pasos de Instalación

1. Instalar dependencias:
```bash
flutter pub get
```

2. Ejecutar la aplicación:
```bash
flutter run
```

## Estructura del Proyecto

```
lib/
├── main.dart                 # Punto de entrada y navegación principal
├── models/                   # Modelos de datos
│   ├── producto.dart
│   ├── proveedor.dart
│   ├── compra.dart
│   └── venta.dart
├── screens/                  # Pantallas de la aplicación
│   ├── productos_screen.dart
│   ├── punto_venta_screen.dart
│   └── proveedores_screen.dart
└── services/                 # Servicios
    └── database_helper.dart  # Gestión de base de datos SQLite
```

## Base de Datos

La aplicación utiliza SQLite con las siguientes tablas:

- **productos**: Información de productos
- **proveedores**: Datos de proveedores
- **compras**: Registro de compras a proveedores
- **ventas**: Registro de ventas
- **detalles_venta**: Productos vendidos en cada venta

## Pantallas

### 1. Punto de Venta
- Grid de productos disponibles
- Carrito de compras interactivo
- Modal de pago con botones de billetes
- Cálculo automático de cambio

### 2. Productos
- Lista de productos con stock actual
- Formulario para agregar/editar productos
- Eliminación de productos con confirmación
- Alertas visuales para productos con bajo stock

### 3. Proveedores y Compras
- **Tab Proveedores**: Lista y gestión de proveedores
- **Tab Compras**: Historial de compras
- Formulario de registro de compras

## Flujo de Trabajo

### Realizar una Venta
1. Ir a "Punto de Venta"
2. Seleccionar productos del grid
3. Ajustar cantidades en el carrito
4. Presionar "PROCESAR PAGO"
5. Seleccionar billete o ingresar monto manualmente
6. Confirmar pago (el sistema calcula el cambio)

### Registrar una Compra
1. Ir a "Proveedores" → Tab "Compras"
2. Presionar el botón "+"
3. Seleccionar proveedor y producto
4. Ingresar cantidad y precio unitario
5. Guardar (el stock se actualiza automáticamente)

## Personalización

### Imágenes de Billetes
Para usar imágenes reales de billetes en lugar de iconos:

1. Agregar imágenes PNG en `assets/images/`:
   - billete_20.png
   - billete_50.png
   - billete_100.png
   - billete_200.png
   - billete_500.png
   - billete_1000.png

2. Modificar el widget de billetes en `punto_venta_screen.dart` para usar `Image.asset()` en lugar del `Icon()`

## Mejoras Futuras

- Reportes de ventas y gráficos
- Exportar datos a Excel/PDF
- Búsqueda avanzada de productos
- Scanner de código de barras
- Múltiples usuarios con permisos
- Respaldo automático en la nube
- Modo offline completo

## Licencia

Proyecto de uso libre para tiendas de abarrotes.

## Autor

Desarrollado para facilitar la gestión de pequeños comercios.

