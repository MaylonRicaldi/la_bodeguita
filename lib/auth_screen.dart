import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'clientes_screen.dart';

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController entradaController = TextEditingController(); // correo o teléfono
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController contrasenaController = TextEditingController();

  bool isLogin = true;
  bool isLoading = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ===============================
  // REGISTRAR USUARIO NUEVO
  // ===============================
  Future<void> registrarUsuario() async {
    setState(() => isLoading = true);

    try {
      String entrada = entradaController.text.trim();
      String contrasena = contrasenaController.text.trim();
      String nombre = nombreController.text.trim();

      if (entrada.isEmpty || contrasena.isEmpty || nombre.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Por favor completa todos los campos")),
        );
        setState(() => isLoading = false);
        return;
      }

      // Detectar si es correo o teléfono
      bool esCorreo = entrada.contains('@');

      // Generar ID automático tipo USU001
      QuerySnapshot snapshot = await _firestore.collection('usuarios').get();
      int nuevoId = snapshot.docs.length + 1;
      String userId = 'USU${nuevoId.toString().padLeft(3, '0')}';

      // Guardar en Firestore
      await _firestore.collection('usuarios').doc(userId).set({
        'id': userId,
        'nombre': nombre,
        'email': esCorreo ? entrada : '',
        'telefono': esCorreo ? '' : entrada,
        'contrasena': contrasena,
        'fechaRegistro': DateTime.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Usuario registrado exitosamente")),
      );

      setState(() => isLogin = true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al registrar: $e")),
      );
    }

    setState(() => isLoading = false);
  }

  // ===============================
  // INICIAR SESIÓN
  // ===============================
  Future<void> iniciarSesion() async {
  setState(() => isLoading = true);

  try {
    String entrada = entradaController.text.trim();
    String contrasena = contrasenaController.text.trim();

    // Detectar si es correo o teléfono
    bool esCorreo = entrada.contains('@');

    // Consulta a Firestore directamente según el tipo de entrada
    QuerySnapshot usuarios = await _firestore
        .collection('usuarios')
        .where(esCorreo ? 'email' : 'telefono', isEqualTo: entrada)
        .where('contrasena', isEqualTo: contrasena)
        .get();

    if (usuarios.docs.isNotEmpty) {
      var usuarioEncontrado = usuarios.docs.first.data() as Map<String, dynamic>;

      // ✅ Ir directamente a la pantalla de clientes
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ClientesScreen(usuarioData: usuarioEncontrado),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Correo/teléfono o contraseña incorrectos")),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error al iniciar sesión: $e")),
    );
  }

  setState(() => isLoading = false);
}


  // ===============================
  // UI
  // ===============================
  @override
  Widget build(BuildContext context) {
    final color = Colors.teal;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.store, color: Colors.teal, size: 100),
              const SizedBox(height: 20),
              Text(
                isLogin ? "Iniciar Sesión" : "Crear Cuenta",
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              if (!isLogin)
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(labelText: "Nombre completo"),
                ),
              TextField(
                controller: entradaController,
                decoration: const InputDecoration(
                    labelText: "Correo electrónico o teléfono"),
              ),
              TextField(
                controller: contrasenaController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Contraseña"),
              ),
              const SizedBox(height: 20),
              isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: isLogin ? iniciarSesion : registrarUsuario,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 14),
                      ),
                      child: Text(
                        isLogin ? "Ingresar" : "Registrar",
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => setState(() => isLogin = !isLogin),
                child: Text(
                  isLogin
                      ? "¿No tienes cuenta? Regístrate"
                      : "¿Ya tienes cuenta? Inicia sesión",
                  style: const TextStyle(color: Colors.teal),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
