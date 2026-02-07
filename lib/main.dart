import 'package:flutter/material.dart';
import 'screens/punto_venta_screen.dart';
import 'screens/productos_screen.dart';
import 'screens/proveedores_screen.dart';
import 'screens/caja_screen.dart';
import 'screens/historial_ventas_screen.dart';
import 'screens/corte_dia_screen.dart';
import 'screens/configuracion_screen.dart';
import 'services/user_profile_service.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Punto de Venta',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  UserProfileService? _profileService;

  Widget _getScreen(int index) {
    switch (index) {
      case 0:
        return const PuntoVentaScreen();
      case 1:
        return const ProductosScreen();
      case 2:
        return const CajaScreen();
      case 3:
        return const ProveedoresScreen();
      case 4:
        return const HistorialVentasScreen();
      case 5:
        return const CorteDiaScreen();
      case 6:
        return const ConfiguracionScreen();
      default:
        return const PuntoVentaScreen();
    }
  }

  @override
  void initState() {
    super.initState();
    _verificarPerfil();
  }

  Future<void> _verificarPerfil() async {
    _profileService = await UserProfileService.getInstance();
    
    if (_profileService!.shouldShowProfileAlert()) {
      await _profileService!.updateLastProfileCheck();
      
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _mostrarAlertaPerfil();
          }
        });
      }
    }
  }

  void _mostrarAlertaPerfil() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.person_add, color: Colors.orange[700], size: 28),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                '¡Personaliza tu Perfil!',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Para que tu nombre aparezca en los cortes de caja, configura tu perfil de usuario.',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.deepPurple[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.deepPurple[700], size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Ve a Configuración para añadir tu información',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Después'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _selectedIndex = 6; // Configuración
              });
            },
            icon: const Icon(Icons.settings),
            label: const Text('Ir a Configuración'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getScreen(_selectedIndex),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.point_of_sale_rounded),
              label: 'Venta',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_rounded),
              label: 'Productos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_rounded),
              label: 'Caja',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_rounded),
              label: 'Proveedores',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_rounded),
              label: 'Historial',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pie_chart_rounded),
              label: 'Corte',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded),
              label: 'Config',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.deepPurple,
          unselectedItemColor: Colors.grey[400],
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 12,
          unselectedFontSize: 11,
          elevation: 8,
          backgroundColor: Colors.white,
        ),
      ),
    );
  }
}

