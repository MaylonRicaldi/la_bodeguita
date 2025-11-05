// ===================== IMPORTS =====================
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ===================== SCREENS =====================
import 'productos_screen.dart';
import 'clientes_screen.dart';
import 'tienda_screen.dart';

// ===================== MAIN =====================
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseAuth.instance.signOut(); // Cierra sesión cada vez que abre la app
  runApp(MyApp());
}

// ===================== MYAPP =====================
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'App Firestore',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: SplashScreen(),
    );
  }
}

// ===================== SPLASH SCREEN =====================
class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  double progress = 0.0;
  late Timer _timer;
  double nube1X = 0;
  double nube2X = 100;
  bool movingRight = false;
  int frame = 0; // para alternar las imágenes del carrito

  @override
  void initState() {
    super.initState();

    // 🌥️ Movimiento más amplio y suave de las nubes
    Timer.periodic(const Duration(milliseconds: 40), (timer) {
      if (!mounted) return;
      setState(() {
        if (movingRight) {
          nube1X += 0.4;
          nube2X -= 0.3;
          if (nube1X > 20) movingRight = false;
        } else {
          nube1X -= 0.4;
          nube2X += 0.3;
          if (nube1X < -20) movingRight = true;
        }
      });
    });

    // Barra de progreso (6 segundos)
    _timer = Timer.periodic(const Duration(milliseconds: 60), (timer) {
      if (!mounted) return;
      setState(() {
        progress += (100 / (6000 / 60));
        frame++;
        if (progress >= 100) {
          progress = 100;
          _timer.cancel();
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  transitionDuration: const Duration(milliseconds: 800),
                  pageBuilder: (_, __, ___) => HomePage(initialIndex: 0),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                ),
              );
            }
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double barraAncho = MediaQuery.of(context).size.width - 80;
    final double carritoAncho = 80;
    final double posicionCarrito =
        (progress / 100) * (barraAncho - carritoAncho);

    return Scaffold(
      body: Stack(
        children: [
          // Fondo
          Positioned.fill(
            child: Image.asset('assets/fondo_parque.png', fit: BoxFit.cover),
          ),

          // Nubes animadas
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            top: 60,
            left: 50 + nube1X,
            child: Image.asset('assets/nube1.png', width: 120),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            top: 100,
            right: 80 + nube2X,
            child: Image.asset('assets/nube2.png', width: 150),
          ),

          // Contenido central
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/logo.png', width: 180, height: 180),
                const SizedBox(height: 50),

                // Stack para superponer carrito sobre barra
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Barra de progreso
                      ShaderMask(
                        shaderCallback: (bounds) {
                          return const LinearGradient(
                            colors: [
                              Color(0xFF00BCD4),
                              Color(0xFF26C6DA),
                              Color(0xFF00ACC1),
                            ],
                            stops: [0.0, 0.5, 1.0],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ).createShader(bounds);
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: LinearProgressIndicator(
                            value: progress / 100,
                            minHeight: 16,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            color: Colors.white,
                          ),
                        ),
                      ),

                      // Carrito caminando sobre la barra
                      Positioned(
                        bottom: 10,
                        left: posicionCarrito,
                        child: Image.asset(
                          progress >= 100
                              ? 'assets/carrito3.png'
                              : (frame % 10 < 5
                                  ? 'assets/carrito1.png'
                                  : 'assets/carrito2.png'),
                          width: carritoAncho,
                          height: 80,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                AnimatedOpacity(
                  opacity: 1.0,
                  duration: const Duration(milliseconds: 500),
                  child: Text(
                    "Cargando... ${progress.toInt()}%",
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===================== HOME PAGE =====================
class HomePage extends StatefulWidget {
  final int initialIndex;
  final Map<String, dynamic>? usuarioData;

  const HomePage({Key? key, this.initialIndex = 0, this.usuarioData})
      : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late int _selectedIndex;
  Map<String, dynamic>? usuarioData;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    usuarioData = widget.usuarioData;
    _cargarUsuarioSiExiste();
  }

  Future<void> _cargarUsuarioSiExiste() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => usuarioData = null);
      return;
    }

    try {
      final snap = await FirebaseFirestore.instance
          .collection('Usuarios')
          .doc(user.uid)
          .get();

      if (snap.exists) {
        setState(() => usuarioData = snap.data());
      } else {
        setState(() {
          usuarioData = {
            'nombre': user.displayName ?? 'Usuario',
            'email': user.email ?? '',
            'uid': user.uid,
          };
        });
      }
    } catch (e) {
      debugPrint("⚠️ Error al cargar usuario: $e");
    }
  }

  void _onTapNav(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      ProductosScreen(),
      ClientesScreen(usuarioData: usuarioData),
      TiendaScreen(),
    ];

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTapNav,
        selectedItemColor: Colors.teal,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Productos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store_mall_directory),
            label: 'Tienda',
          ),
        ],
      ),
    );
  }
}
