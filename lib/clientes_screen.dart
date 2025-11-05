import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_screen.dart';
import 'historial_pedidos_screen.dart';

class ClientesScreen extends StatefulWidget {
  final Map<String, dynamic>? usuarioData;

  const ClientesScreen({Key? key, this.usuarioData}) : super(key: key);

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  Map<String, dynamic> usuario = {};
  bool _cargando = true;

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
      // si no hay sesión, dejamos vacío (invitado)
      setState(() {
        usuario = {};
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
        setState(() {
          usuario = snap.data()!;
          _cargando = false;
        });
      } else {
        // documento no existe en Firestore, mostramos datos básicos desde Auth
        setState(() {
          usuario = {
            "nombre": user.displayName ?? "Usuario",
            "email": user.email ?? "",
            "uid": user.uid,
          };
          _cargando = false;
        });
      }
    } catch (e) {
      // si falla la lectura, usar datos de Auth si están
      setState(() {
        usuario = {
          "nombre": user?.displayName ?? "Usuario",
          "email": user?.email ?? "",
          "uid": user?.uid ?? "",
        };
        _cargando = false;
      });
    }
  }

  Future<void> _cerrarSesionYirLogin() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const AuthScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final nombre = usuario['nombre'] ?? 'Invitado';
    final correo = usuario['email'] ?? usuario['telefono'] ?? '';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.teal,
        centerTitle: true,
        title: const Text("Mi Perfil"),
        actions: [
          // cerrar sesión en la AppBar (solo ícono)
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _cerrarSesionYirLogin,
            tooltip: "Cerrar sesión",
          )
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
                      const CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.teal,
                        child: Icon(Icons.person, size: 60, color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        nombre,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
                      MaterialPageRoute(builder: (_) => const HistorialPedidosScreen()),
                    );
                  },
                ),

                _itemMenu(
                  icono: Icons.favorite_border,
                  titulo: "Favoritos",
                  subtitulo: "Tus productos guardados",
                  onTap: () {},
                ),
              ],
            ),
          ),

          // Loader encima mientras cargamos los datos (no borra la UI)
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