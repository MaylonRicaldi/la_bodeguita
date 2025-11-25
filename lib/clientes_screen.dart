import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_screen.dart';
import 'historial_pedidos_screen.dart';
import 'favoritos_screen.dart';

class ClientesScreen extends StatefulWidget {
  final Map<String, dynamic>? usuarioData;

  const ClientesScreen({Key? key, this.usuarioData}) : super(key: key);

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> with TickerProviderStateMixin {
  Map<String, dynamic> usuario = {};
  bool _cargando = true;
  String? fotoBase64;
  bool cargandoFoto = false;
  
  // Para la animación Polaroid
  bool _mostrarPolaroid = false;
  String? _fotoPolaroid;
  late AnimationController _polaroidController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    usuario = widget.usuarioData ?? {};
    _cargarUsuarioFirebase();
    
    // Configurar animación Polaroid
    _polaroidController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(begin: 1.5, end: 0.0).animate(
      CurvedAnimation(
        parent: _polaroidController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _polaroidController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeIn),
      ),
    );
  }

  @override
  void dispose() {
    _polaroidController.dispose();
    super.dispose();
  }

  Future<void> _cargarUsuarioFirebase() async {
    setState(() => _cargando = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        usuario = {};
        fotoBase64 = null;
        _cargando = false;
      });
      return;
    }

    try {
      final snap = await FirebaseFirestore.instance
          .collection("Usuarios")
          .doc(user.uid)
          .get();

      if (snap.exists) {
        final data = snap.data()!;
        setState(() {
          usuario = data;
          fotoBase64 = data['fotoBase64'];
          _cargando = false;
        });
      } else {
        setState(() {
          usuario = {
            "nombre": user.displayName ?? "Usuario",
            "email": user.email ?? "",
            "uid": user.uid,
          };
          fotoBase64 = null;
          _cargando = false;
        });
      }
    } catch (e) {
      setState(() {
        usuario = {
          "nombre": user?.displayName ?? "Usuario",
          "email": user?.email ?? "",
          "uid": user?.uid ?? "",
        };
        fotoBase64 = null;
        _cargando = false;
      });
    }
  }

  Future<void> _efectoFlash() async {
    // Efecto de flash blanco
    showDialog(
      context: context,
      barrierColor: Colors.white,
      barrierDismissible: false,
      builder: (_) => const SizedBox.shrink(),
    );
    
    await Future.delayed(const Duration(milliseconds: 150));
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _mostrarAnimacionPolaroid(String base64Image) async {
    setState(() {
      _fotoPolaroid = base64Image;
      _mostrarPolaroid = true;
    });
    
    _polaroidController.forward(from: 0.0);
    
    await Future.delayed(const Duration(milliseconds: 2500));
    
    if (mounted) {
      setState(() => _mostrarPolaroid = false);
      _polaroidController.reset();
    }
  }

  Future<void> seleccionarImagen(bool desdeCamara) async {
    final picker = ImagePicker();

    final XFile? img = await picker.pickImage(
      source: desdeCamara ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 600,
    );

    if (img == null) return;

    // Vibración y flash
    HapticFeedback.mediumImpact();
    await _efectoFlash();

    setState(() => cargandoFoto = true);

    try {
      final bytes = await File(img.path).readAsBytes();
      final base64String = base64Encode(bytes);

      final uid = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance
          .collection("Usuarios")
          .doc(uid)
          .update({"fotoBase64": base64String});

      setState(() {
        fotoBase64 = base64String;
        cargandoFoto = false;
      });

      // ✨ ANIMACIÓN POLAROID
      await _mostrarAnimacionPolaroid(base64String);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("¡Foto de perfil actualizada! 📸")),
      );
    } catch (e) {
      setState(() => cargandoFoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al actualizar foto")),
      );
    }
  }

  void mostrarOpcionesFoto() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.tealAccent),
              title: const Text("Tomar foto", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                seleccionarImagen(true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.tealAccent),
              title: const Text("Elegir de galería", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                seleccionarImagen(false);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cerrarSesion() async {
    await FirebaseAuth.instance.signOut();
    _cargarUsuarioFirebase();
  }

  @override
  Widget build(BuildContext context) {
    final nombre = usuario['nombre'] ?? 'Invitado';
    final correo = usuario['email'] ?? usuario['telefono'] ?? '';
    final userLogueado = FirebaseAuth.instance.currentUser != null;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.teal,
        centerTitle: true,
        title: Text(
          "Mi Perfil",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          if (userLogueado)
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: _cerrarSesion,
              tooltip: "Cerrar sesión",
            )
          else
            IconButton(
              icon: const Icon(Icons.login, color: Colors.white),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                );
                _cargarUsuarioFirebase();
              },
              tooltip: "Iniciar sesión",
            ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: userLogueado ? mostrarOpcionesFoto : null,
                        child: Stack(
                          children: [
                            cargandoFoto
                                ? const CircleAvatar(
                                    radius: 45,
                                    backgroundColor: Colors.teal,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  )
                                : CircleAvatar(
                                    radius: 45,
                                    backgroundColor: Colors.teal,
                                    backgroundImage: fotoBase64 != null
                                        ? MemoryImage(base64Decode(fotoBase64!))
                                        : null,
                                    child: fotoBase64 == null
                                        ? const Icon(Icons.person,
                                            size: 60, color: Colors.white)
                                        : null,
                                  ),
                            if (userLogueado && !cargandoFoto)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.teal,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        nombre,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        correo,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                _itemMenu(
                  icono: Icons.shopping_bag_outlined,
                  titulo: "Mis pedidos",
                  subtitulo: "Ver historial de compras",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const HistorialPedidosScreen()),
                    );
                  },
                ),

                _itemMenu(
                  icono: Icons.favorite_border,
                  titulo: "Favoritos",
                  subtitulo: "Tus productos guardados",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const FavoritosScreen()),
                    );
                  },
                ),
              ],
            ),
          ),

          if (_cargando)
            Container(
              color: Colors.black.withOpacity(0.2),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.teal),
              ),
            ),

          // ✨ ANIMACIÓN POLAROID
          if (_mostrarPolaroid && _fotoPolaroid != null)
            AnimatedBuilder(
              animation: _polaroidController,
              builder: (context, child) {
                return Positioned(
                  bottom: MediaQuery.of(context).size.height * _slideAnimation.value,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: Transform.rotate(
                        angle: -0.05,
                        child: Container(
                          width: 200,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.memory(
                                  base64Decode(_fotoPolaroid!),
                                  width: 170,
                                  height: 170,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "¡Foto guardada! 📸",
                                style: TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 14,
                                  color: Colors.grey[800],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _itemMenu({
    required IconData icono,
    required String titulo,
    required String subtitulo,
    required VoidCallback onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.teal.withOpacity(0.1),
          child: Icon(icono, color: Colors.teal),
        ),
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitulo),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: onTap,
      ),
    );
  }
}