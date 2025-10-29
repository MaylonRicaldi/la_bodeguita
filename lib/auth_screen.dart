import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'clientes_screen.dart';
import 'main.dart';

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController entradaController = TextEditingController();
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController contrasenaController = TextEditingController();

  bool isLogin = true;
  bool isLoading = false;
  bool ocultarPassword = true;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

      bool esCorreo = entrada.contains('@');

      QuerySnapshot snapshot = await _firestore.collection('usuarios').get();
      int nuevoId = snapshot.docs.length + 1;
      String userId = 'USU${nuevoId.toString().padLeft(3, '0')}';

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

  Future<void> iniciarSesion() async {
    setState(() => isLoading = true);
    try {
      String entrada = entradaController.text.trim();
      String contrasena = contrasenaController.text.trim();

      bool esCorreo = entrada.contains('@');

      QuerySnapshot usuarios = await _firestore
          .collection('usuarios')
          .where(esCorreo ? 'email' : 'telefono', isEqualTo: entrada)
          .where('contrasena', isEqualTo: contrasena)
          .get();

      if (usuarios.docs.isNotEmpty) {
        var usuarioEncontrado =
            usuarios.docs.first.data() as Map<String, dynamic>;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(
              initialIndex: 1,
              usuarioData: usuarioEncontrado,
            ),
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

  @override
  Widget build(BuildContext context) {
    final color = Colors.teal;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00BFA5), Color(0xFF00796B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.storefront_rounded,
                      color: Colors.teal, size: 80),
                  const SizedBox(height: 12),
                  Text(
                    isLogin ? "Bienvenido de nuevo" : "Crear nueva cuenta",
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isLogin
                        ? "Inicia sesión para continuar"
                        : "Completa tus datos para registrarte",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 25),

                  if (!isLogin)
                    TextField(
                      controller: nombreController,
                      decoration: InputDecoration(
                        labelText: "Nombre completo",
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  if (!isLogin) const SizedBox(height: 15),

                  TextField(
                    controller: entradaController,
                    decoration: InputDecoration(
                      labelText: "Correo electrónico o teléfono",
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  TextField(
                    controller: contrasenaController,
                    obscureText: ocultarPassword,
                    decoration: InputDecoration(
                      labelText: "Contraseña",
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          ocultarPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () =>
                            setState(() => ocultarPassword = !ocultarPassword),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),
                  isLoading
                      ? const CircularProgressIndicator(color: Colors.teal)
                      : ElevatedButton(
                          onPressed:
                              isLogin ? iniciarSesion : registrarUsuario,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            isLogin ? "Iniciar sesión" : "Registrar cuenta",
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                  const SizedBox(height: 15),
                  TextButton(
                    onPressed: () => setState(() => isLogin = !isLogin),
                    child: Text(
                      isLogin
                          ? "¿No tienes cuenta? Regístrate"
                          : "¿Ya tienes cuenta? Inicia sesión",
                      style: const TextStyle(
                        color: Colors.teal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
