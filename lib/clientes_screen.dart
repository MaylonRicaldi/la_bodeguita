import 'package:flutter/material.dart';
import 'auth_screen.dart'; // Para regresar al login

class ClientesScreen extends StatelessWidget {
  final Map<String, dynamic>? usuarioData;

  const ClientesScreen({Key? key, this.usuarioData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final usuario = usuarioData ?? {};
    final nombre = usuario['nombre'] ?? 'Invitado';
    final correo = usuario['email'] ?? '';
    final telefono = usuario['telefono'] ?? '';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.teal,
        centerTitle: true,
        title: const Text("Mi Perfil"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ----------------------------
            // Perfil del usuario
            // ----------------------------
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
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
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    correo.isNotEmpty ? correo : telefono,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // ----------------------------
            // Opciones del perfil
            // ----------------------------
            _opcionItem(
              context,
              icono: Icons.shopping_bag_outlined,
              titulo: "Mis pedidos",
              subtitulo: "Ver historial de compras",
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Sección de pedidos próximamente")),
                );
              },
            ),
            _opcionItem(
              context,
              icono: Icons.favorite_outline,
              titulo: "Favoritos",
              subtitulo: "Tus productos guardados",
              onTap: () {},
            ),

            const SizedBox(height: 25),

            // ----------------------------
            // Botón de cerrar sesión
            // ----------------------------
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => AuthScreen()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text(
                "Cerrar sesión",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------
  // Widget auxiliar para opciones
  // ----------------------------
  Widget _opcionItem(BuildContext context,
      {required IconData icono,
      required String titulo,
      required String subtitulo,
      required VoidCallback onTap}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.teal.withOpacity(0.1),
          child: Icon(icono, color: Colors.teal),
        ),
        title: Text(
          titulo,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitulo),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: onTap,
      ),
    );
  }
}
