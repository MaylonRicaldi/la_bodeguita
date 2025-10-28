import 'package:flutter/material.dart';

class ClientesScreen extends StatelessWidget {
  final Map<String, dynamic>? usuarioData;

  const ClientesScreen({Key? key, this.usuarioData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final usuario = usuarioData ?? {};

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person, size: 100, color: Colors.teal),
          Text(
            'Hola, ${usuario['nombre'] ?? 'Invitado'}',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text('Correo: ${usuario['email'] ?? 'Sin correo'}'),
          Text('Teléfono: ${usuario['telefono'] ?? 'Sin teléfono'}'),
        ],
      ),
    );
  }
}
