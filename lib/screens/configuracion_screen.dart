import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../models/categoria.dart';
import '../services/database_helper.dart';
import '../services/user_profile_service.dart';

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  final _dbHelper = DatabaseHelper.instance;
  static const String _telefonoContacto = '8331811916';
  List<Categoria> _categoriasBase = [];
  List<Categoria> _subcategorias = [];
  bool _isLoading = true;
  bool _isBackingUp = false;
  UserProfileService? _profileService;
  String? _userName;
  String? _businessName;
  final Set<int> _categoriasExpandidas = {};

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
    _cargarPerfil();
  }
  
  Future<void> _cargarPerfil() async {
    _profileService = await UserProfileService.getInstance();
    setState(() {
      _userName = _profileService!.getUserName();
      _businessName = _profileService!.getBusinessName();
    });
  }

  Future<void> _cargarCategorias() async {
    setState(() => _isLoading = true);
    final categoriasBase = await _dbHelper.getCategoriasBase();
    final subcategorias = await _dbHelper.getAllSubcategorias();
    setState(() {
      _categoriasBase = categoriasBase;
      _subcategorias = subcategorias;
      _isLoading = false;
    });
  }

  void _mostrarDialogoNuevaCategoria({Categoria? categoriaPadre}) {
    final nombreController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                categoriaPadre == null ? 'Nueva Categoría' : 'Nueva Subcategoría',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              if (categoriaPadre != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.label, color: Colors.deepPurple, size: 16),
                      const SizedBox(width: 8),
                      const Text('Categoría padre: ', style: TextStyle(fontSize: 13)),
                      Text(
                        categoriaPadre.nombre,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              TextField(
                controller: nombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre',
                  hintText: categoriaPadre == null
                      ? 'Ej: Bebidas, Abarrotes'
                      : 'Ej: FEMSA, Coca-Cola',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                autofocus: true,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (nombreController.text.isNotEmpty) {
                    await _dbHelper.insertCategoria(
                      Categoria(
                        nombre: nombreController.text,
                        categoriaParentId: categoriaPadre?.id,
                      ),
                    );
                    await _cargarCategorias();
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Guardar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _mostrarDialogoEditarPerfil(String titulo, String? valorActual, bool esNombreUsuario) {
    final controller = TextEditingController(text: valorActual);
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    esNombreUsuario ? Icons.person : Icons.store,
                    color: esNombreUsuario ? Colors.deepPurple : Colors.orange,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      titulo,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: titulo,
                  hintText: esNombreUsuario 
                      ? 'Ej: Juan Pérez' 
                      : 'Ej: Abarrotes Don Pepe',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  prefixIcon: Icon(
                    esNombreUsuario ? Icons.person_outline : Icons.store_outlined,
                    color: esNombreUsuario ? Colors.deepPurple : Colors.orange,
                  ),
                ),
                autofocus: true,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (controller.text.isNotEmpty) {
                    if (esNombreUsuario) {
                      await _profileService!.setUserName(controller.text);
                    } else {
                      await _profileService!.setBusinessName(controller.text);
                    }
                    await _cargarPerfil();
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$titulo actualizado correctamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: esNombreUsuario ? Colors.deepPurple : Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Guardar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _crearBackup() async {
    setState(() => _isBackingUp = true);
    try {
      final ruta = await _dbHelper.crearBackupLocal();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Respaldo guardado exitosamente:\n${ruta.split('/').last}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear respaldo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isBackingUp = false);
    }
  }

  Future<void> _mostrarBackupsDisponibles() async {
    final backups = await _dbHelper.getBackupsDisponibles();
    if (!mounted) return;

    if (backups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay respaldos disponibles'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Restaurar Respaldo',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Selecciona un respaldo para restaurar. Esto reemplazará todos los datos actuales.',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: backups.length,
                  itemBuilder: (context, index) {
                    final backup = backups[index];
                    final nombre = backup.path.split(Platform.pathSeparator).last;
                    final stat = File(backup.path).statSync();
                    final fecha = DateFormat('dd/MM/yyyy HH:mm').format(stat.modified);
                    final tamano = (stat.size / 1024).toStringAsFixed(1);
                    
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.storage, color: Colors.teal),
                        title: Text(nombre, style: const TextStyle(fontSize: 13)),
                        subtitle: Text('$fecha • ${tamano}KB', style: const TextStyle(fontSize: 11)),
                        onTap: () async {
                          Navigator.pop(context);
                          final confirmar = await showDialog<bool>(
                            context: this.context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('¿Restaurar respaldo?'),
                              content: const Text(
                                'Esto reemplazará TODOS los datos actuales. Esta acción no se puede deshacer.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancelar'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Restaurar'),
                                ),
                              ],
                            ),
                          );
                          if (confirmar == true) {
                            try {
                              await _dbHelper.restaurarBackup(backup.path);
                              await _cargarCategorias();
                              if (!mounted) return;
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(
                                  content: Text('Respaldo restaurado exitosamente. Reinicia la app para ver todos los cambios.'),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 4),
                                ),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                SnackBar(
                                  content: Text('Error al restaurar: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _abrirWhatsApp() async {
    final uri = Uri.parse('https://wa.me/52$_telefonoContacto');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir WhatsApp')),
      );
    }
  }

  Future<void> _llamarTelefono() async {
    final uri = Uri.parse('tel:$_telefonoContacto');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo iniciar la llamada')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Configuración',
            style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Sección de Perfil
                const Text(
                  'Perfil de Usuario',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Personaliza tu información de tienda',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.deepPurple[100],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.person,
                              color: Colors.deepPurple[700], size: 20),
                        ),
                        title: const Text(
                          'Nombre del Encargado',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          _userName ?? 'No configurado',
                          style: TextStyle(
                            fontSize: 13,
                            color: _userName == null ? Colors.red : Colors.grey[600],
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit, color: Colors.deepPurple),
                          onPressed: () => _mostrarDialogoEditarPerfil('Nombre del Encargado', _userName, true),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.store,
                              color: Colors.orange[700], size: 20),
                        ),
                        title: const Text(
                          'Nombre del Negocio',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          _businessName ?? 'Tienda de Abarrotes',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          onPressed: () => _mostrarDialogoEditarPerfil('Nombre del Negocio', _businessName, false),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Categorías Base',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Categorías principales de productos',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      ..._categoriasBase.asMap().entries.map((entry) {
                        final index = entry.key;
                        final cat = entry.value;
                        final subcats = _subcategorias
                            .where((s) => s.categoriaParentId == cat.id)
                            .toList();
                        final isExpanded = _categoriasExpandidas.contains(cat.id);
                        
                        return Column(
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 8),
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: cat.color != null
                                      ? _hexToColor(cat.color!)
                                      : Colors.deepPurple,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.category,
                                    color: Colors.white, size: 20),
                              ),
                              title: Text(
                                cat.nombre,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              subtitle: subcats.isNotEmpty
                                  ? Text(
                                      '${subcats.length} ${subcats.length == 1 ? 'subcategoría' : 'subcategorías'}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.deepPurple[600],
                                      ),
                                    )
                                  : null,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (subcats.isNotEmpty)
                                    IconButton(
                                      icon: AnimatedRotation(
                                        turns: isExpanded ? 0.5 : 0,
                                        duration: const Duration(milliseconds: 200),
                                        child: Icon(Icons.expand_more,
                                            color: Colors.deepPurple[400]),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          if (isExpanded) {
                                            _categoriasExpandidas.remove(cat.id);
                                          } else {
                                            _categoriasExpandidas.add(cat.id!);
                                          }
                                        });
                                      },
                                      tooltip: isExpanded ? 'Ocultar subcategorías' : 'Ver subcategorías',
                                    ),
                                  IconButton(
                                    icon: Icon(Icons.add_circle_outline,
                                        color: Colors.deepPurple[400]),
                                    onPressed: () =>
                                        _mostrarDialogoNuevaCategoria(
                                            categoriaPadre: cat),
                                    tooltip: 'Agregar subcategoría',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () async {
                                      await _dbHelper.deleteCategoria(cat.id!);
                                      _cargarCategorias();
                                    },
                                  ),
                                ],
                              ),
                            ),
                            // Subcategorías desplegables
                            AnimatedCrossFade(
                              firstChild: const SizedBox.shrink(),
                              secondChild: Container(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey[800]
                                    : Colors.grey[50],
                                child: Column(
                                  children: subcats.map((subcat) {
                                    return ListTile(
                                      contentPadding: const EdgeInsets.only(
                                          left: 72, right: 20),
                                      leading: Icon(Icons.subdirectory_arrow_right,
                                          size: 18, color: Colors.deepPurple[300]),
                                      title: Text(
                                        subcat.nombre,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete_outline,
                                            color: Colors.red, size: 20),
                                        onPressed: () async {
                                          await _dbHelper.deleteCategoria(subcat.id!);
                                          _cargarCategorias();
                                        },
                                      ),
                                      dense: true,
                                    );
                                  }).toList(),
                                ),
                              ),
                              crossFadeState: isExpanded
                                  ? CrossFadeState.showSecond
                                  : CrossFadeState.showFirst,
                              duration: const Duration(milliseconds: 200),
                            ),
                            if (index < _categoriasBase.length - 1)
                              const Divider(height: 1),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _mostrarDialogoNuevaCategoria,
                  icon: const Icon(Icons.add),
                  label: const Text('Nueva Categoría Base'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
                
                if (_subcategorias.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.grey[500]),
                        const SizedBox(width: 8),
                        Text(
                          'Toca la flecha ▼ para ver las subcategorías',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),
                const Text(
                  'Respaldo',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Guarda un respaldo completo de la base de datos',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isBackingUp ? null : _crearBackup,
                        icon: _isBackingUp
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.backup),
                        label: Text(_isBackingUp ? 'Guardando...' : 'Guardar respaldo local'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _mostrarBackupsDisponibles,
                        icon: const Icon(Icons.restore),
                        label: const Text('Restaurar respaldo'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Los respaldos se guardan en la carpeta de documentos de la app.',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                const Text(
                  'Apariencia',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Personaliza la apariencia de la aplicación',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    secondary: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _profileService?.isDarkMode() == true
                            ? Colors.indigo[100]
                            : Colors.amber[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _profileService?.isDarkMode() == true
                            ? Icons.dark_mode
                            : Icons.light_mode,
                        color: _profileService?.isDarkMode() == true
                            ? Colors.indigo[700]
                            : Colors.amber[700],
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      'Modo Oscuro',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      _profileService?.isDarkMode() == true
                          ? 'Activado'
                          : 'Desactivado',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    value: _profileService?.isDarkMode() ?? false,
                    activeTrackColor: Colors.deepPurple.withValues(alpha: 0.5),
                    activeThumbColor: Colors.deepPurple,
                    onChanged: (value) async {
                      await _profileService?.setDarkMode(value);
                      setState(() {});
                    },
                  ),
                ),

                const SizedBox(height: 32),
                const Text(
                  'Reporte',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Resumen mensual de ventas y cortes',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.assessment),
                        label: const Text('Generar reporte mensual'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Incluira ganancia o perdida del mes, cortes, ventas y productos mas vendidos.',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                const Text(
                  'Información',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildInfoTile('Versión', '1.0.0'),
                      const Divider(),
                      _buildInfoTile(
                        'Prueba gratuita',
                        'Termina en 2 meses. Ejemplo: si instalas hoy, termina el 06/04/2026.',
                      ),
                      const Divider(),
                      _buildInfoTile('Nombre', 'Tienda de Abarrotes'),
                      const Divider(),
                      _buildInfoTile('Desarrollado por', 'Ingeniero Toledo Avalos\nRicardo Ernesto'),
                      const Divider(),
                      _buildInfoTile('Contacto', 'WhatsApp/Llamadas: $_telefonoContacto'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _abrirWhatsApp,
                              icon: const Icon(Icons.chat),
                              label: const Text('WhatsApp'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[600],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _llamarTelefono,
                              icon: const Icon(Icons.call),
                              label: const Text('Llamar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[600],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              softWrap: true,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
