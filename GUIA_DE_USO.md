# Guía de Uso - Sistema Punto de Venta

## 🚀 Cómo Ejecutar la Aplicación

### Opción 1: Usar un Emulador
1. Abrir Android Studio o iniciar un emulador desde VS Code
2. En la terminal, ejecutar:
   ```bash
   flutter run
   ```

### Opción 2: Usar tu Dispositivo Móvil
1. Habilitar modo desarrollador en tu teléfono
2. Conectar el teléfono por USB
3. Ejecutar `flutter run`

### Opción 3: Modo Web (Para pruebas rápidas)
```bash
flutter run -d chrome
```

## 📱 Navegación de la Aplicación

La aplicación tiene 3 secciones principales en la barra inferior:

### 1. 🏪 Punto de Venta (Primera pantalla)

**Cómo realizar una venta:**

1. **Agregar productos al carrito:**
   - En la parte izquierda verás todos tus productos en un grid
   - Haz clic en un producto para agregarlo al carrito
   - El carrito aparece en la parte derecha

2. **Ajustar cantidades:**
   - En el carrito, usa los botones + y - para cambiar la cantidad
   - También puedes eliminar productos con el ícono de basura

3. **Procesar el pago:**
   - Presiona el botón verde "PROCESAR PAGO"
   - Se abrirá una ventana de pago con opciones de billetes

4. **Seleccionar forma de pago:**
   - **Opción A - Billetes rápidos:** Haz clic en cualquier billete ($20, $50, $100, $200, $500, $1000)
   - **Opción B - Monto manual:** Escribe la cantidad que el cliente pagó en el campo "Monto pagado"
   
5. **Ver el cambio:**
   - El sistema calculará automáticamente cuánto cambio debes dar
   - Si el monto es menor al total, aparecerá en rojo

6. **Confirmar:**
   - Presiona "CONFIRMAR PAGO"
   - El inventario se actualizará automáticamente
   - El carrito se vaciará para la siguiente venta

### 2. 📦 Productos (Segunda pantalla)

**Agregar un nuevo producto:**

1. Presiona el botón "+" flotante (naranja/verde)
2. Llena el formulario:
   - **Nombre:** Requerido (ej: "Coca Cola 600ml")
   - **Descripción:** Opcional (ej: "Refresco de cola")
   - **Precio:** Requerido (ej: 15.50)
   - **Stock:** Requerido (ej: 50)
   - **Código de barras:** Opcional
3. Presiona "Guardar"

**Editar un producto:**

1. En la lista, presiona el ícono de lápiz azul
2. Modifica los campos necesarios
3. Presiona "Actualizar"

**Eliminar un producto:**

1. Presiona el ícono de basura rojo
2. Confirma la eliminación

**Alertas de stock:**
- Los productos con 5 unidades o menos se marcan en rojo
- Revisa regularmente para hacer pedidos

### 3. 🏢 Proveedores (Tercera pantalla)

Esta pantalla tiene 2 pestañas:

#### Tab "Proveedores"

**Agregar un proveedor:**

1. Presiona el botón "+"
2. Llena los datos:
   - **Nombre:** Requerido
   - **Teléfono:** Opcional
   - **Email:** Opcional
   - **Dirección:** Opcional
3. Presiona "Guardar"

#### Tab "Compras"

**Registrar una compra:**

1. Ve a la pestaña "Compras"
2. Presiona el botón "+"
3. Selecciona:
   - **Proveedor:** ¿A quién le compraste?
   - **Producto:** ¿Qué compraste?
   - **Cantidad:** ¿Cuántas unidades?
   - **Precio unitario:** ¿A qué precio compraste cada unidad?
   - **Notas:** Información adicional (opcional)
4. Presiona "Registrar Compra"

**Importante:** El stock del producto se actualizará automáticamente cuando registres la compra.

**Ver detalles de una compra:**
- Toca cualquier compra en la lista para expandir y ver todos los detalles

## 💡 Consejos y Buenas Prácticas

### Flujo de trabajo recomendado:

1. **Al inicio:**
   - Registra todos tus proveedores
   - Agrega todos tus productos con stock inicial en 0
   - Registra las compras que has hecho (esto actualizará el stock)

2. **Día a día:**
   - Usa el Punto de Venta para registrar ventas
   - Registra compras cuando recibas mercancía
   - Revisa el stock regularmente

3. **Control de inventario:**
   - Productos en rojo = necesitas hacer pedido
   - Revisa el historial de compras para saber a qué proveedor comprar

### Características especiales del sistema de pago:

- **Billetes por defecto:** Botones prediseñados con las denominaciones más comunes en México
- **Cálculo automático:** No necesitas calcular mentalmente el cambio
- **Validación:** El sistema no permite confirmar si el pago es menor al total
- **Visual claro:** 
  - Cambio en verde = todo correcto
  - Cambio en rojo = el cliente no ha pagado suficiente

### ⚠️ Notas Importantes:

1. **Stock automático:** No modifiques manualmente el stock si has registrado ventas/compras, ya que se actualiza solo
2. **Sin conexión:** La app funciona completamente offline, todos los datos se guardan en tu dispositivo
3. **Respaldo:** Por ahora no hay respaldo automático. Considera hacer copias de seguridad de la base de datos periódicamente

## 🔧 Personalización

### Agregar imágenes de billetes reales:

Los botones de billetes actualmente muestran un ícono genérico. Para usar imágenes reales:

1. Consigue imágenes PNG de billetes mexicanos
2. Guárdalas en: `assets/images/`
   - billete_20.png
   - billete_50.png
   - billete_100.png
   - billete_200.png
   - billete_500.png
   - billete_1000.png
3. El espacio ya está preparado para las imágenes

## ❓ Solución de Problemas

**La app no inicia:**
- Verifica que todas las dependencias estén instaladas: `flutter pub get`
- Asegúrate de tener un emulador o dispositivo conectado

**No veo mis productos en el punto de venta:**
- Ve a la sección "Productos" y agrega productos primero

**El stock no se actualiza:**
- Verifica que hayas confirmado la venta/compra correctamente
- Revisa que el producto exista en la base de datos

**Quiero borrar todos los datos y empezar de nuevo:**
- Desinstala y vuelve a instalar la aplicación
- O borra los datos de la app desde configuración del teléfono

## 📞 Soporte

Para cualquier duda o sugerencia, consulta el archivo README.md del proyecto.

¡Listo para administrar tu tienda! 🎉
