import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'productos_screen.dart';
import 'clientes_screen.dart';
import 'tienda_screen.dart';
import 'dart:async';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Cierra sesión cada vez que se abre la app para permitir crear/usar otra cuenta
  await FirebaseAuth.instance.signOut();

  runApp(MyApp());
}

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

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) return;
      setState(() {
        progress += 2;
        if (progress >= 100) {
          progress = 100;
          _timer.cancel();

          Future.delayed(const Duration(milliseconds: 400), () {
            if (mounted) {
              // ✅ Ir al catálogo (Productos) como antes
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomePage(initialIndex: 0)),
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/logo.png', width: 200, height: 200),
              const SizedBox(height: 40),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress / 100,
                  minHeight: 12,
                  backgroundColor: Colors.grey[300],
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Cargando... ${progress.toInt()}%",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
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
