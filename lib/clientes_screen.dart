import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
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

class _ClientesScreenState extends State<ClientesScreen> {
  Map<String, dynamic> usuario = {};
  bool _cargando = true;
  String? fotoBase64;
  bool cargandoFoto = false;

  @override
  void initState() {
    super.initState();
    usuario = widget.usuarioData ?? {};
    _cargarUsuarioFirebase();
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

  Future<void> seleccionarImagen(bool desdeCamara) async {
    final picker = ImagePicker();

    final XFile? img = await picker.pickImage(
      source: desdeCamara ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 600,
    );

    if (img == null) return;

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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Foto de perfil actualizada")),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.teal),
              title: const Text("Tomar foto"),
              onTap: () {
                Navigator.pop(context);
                seleccionarImagen(true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.teal),
              title: const Text("Elegir de galería"),
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