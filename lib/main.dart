import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'screens/punto_venta_screen.dart';
import 'screens/productos_screen.dart';
import 'screens/proveedores_screen.dart';
import 'screens/caja_screen.dart';
import 'screens/historial_ventas_screen.dart';
import 'screens/corte_dia_screen.dart';
import 'screens/configuracion_screen.dart';
import 'services/user_profile_service.dart';
import 'services/access_guard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final profileService = await UserProfileService.getInstance();
  runApp(
    ChangeNotifierProvider<UserProfileService>.value(
      value: profileService,
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProfileService>(
      builder: (context, profileService, _) {
        final isDark = profileService.isDarkMode();
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
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            fontFamily: 'Roboto',
            inputDecorationTheme: const InputDecorationTheme(
              filled: true,
              fillColor: Color(0xFF2C2C3E),
            ),
          ),
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          home: const AccessGate(),
        );
      },
    );
  }
}

class AccessGate extends StatefulWidget {
  const AccessGate({super.key});

  @override
  State<AccessGate> createState() => _AccessGateState();
}

class _AccessGateState extends State<AccessGate> {
  late final Future<AccessDecision> _statusFuture = _verificarAcceso();

  Future<AccessDecision> _verificarAcceso() async {
    final guard = AccessGuard();
    return guard.checkAccess();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AccessDecision>(
      future: _statusFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: Text('Error al validar la prueba.')),
          );
        }

        final decision = snapshot.data!;
        if (!decision.isAllowed) {
          return AccessBlockedScreen(decision: decision);
        }

        return const HomeScreen();
      },
    );
  }
}

class AccessBlockedScreen extends StatelessWidget {
  final AccessDecision decision;

  const AccessBlockedScreen({super.key, required this.decision});

  @override
  Widget build(BuildContext context) {
    final expiracion = decision.trialExpiry == null
        ? null
        : DateFormat('dd/MM/yyyy HH:mm').format(decision.trialExpiry!);
    final isTampered = decision.reason == AccessBlockReason.trialTampered;
    final title = isTampered ? 'Acceso bloqueado' : 'Suscripción requerida';
    final descripcion = isTampered
        ? 'Se detecto un cambio de fecha en el dispositivo.'
        : (expiracion == null
            ? 'La prueba ha finalizado.'
            : 'La prueba vencio el $expiracion.');
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                descripcion,
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Necesitas una suscripción activa para continuar.',
                style: TextStyle(fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
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
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.orange.withValues(alpha: 0.2)
                    : Colors.orange[100],
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
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.deepPurple.withValues(alpha: 0.15)
                    : Colors.deepPurple[50],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
          unselectedItemColor: isDark ? Colors.grey[500] : Colors.grey[400],
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 12,
          unselectedFontSize: 11,
          elevation: 8,
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        ),
      ),
    );
  }
}

