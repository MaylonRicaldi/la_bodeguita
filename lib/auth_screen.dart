import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pago_screen.dart';

class AuthScreen extends StatefulWidget {
  final bool fromCart;
  final double? total;
  final List<Map<String, dynamic>>? productos;

  const AuthScreen({
    Key? key,
    this.fromCart = false,
    this.total,
    this.productos,
  }) : super(key: key);

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final emailController = TextEditingController();
  final nombreController = TextEditingController();
  final contrasenaController = TextEditingController();

  bool isLogin = true;
  bool isLoading = false;
  bool ocultarPassword = true;

  Future<void> registrarUsuario() async {
    setState(() => isLoading = true);
    try {
      final email = emailController.text.trim();
      final password = contrasenaController.text.trim();
      final nombre = nombreController.text.trim();

      if (email.isEmpty || password.isEmpty || nombre.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Completa todos los campos")),
        );
        setState(() => isLoading = false);
        return;
      }

      // Crear usuario en Firebase Auth
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Guardar datos en Firestore
      await _firestore.collection('Usuarios').doc(cred.user!.uid).set({
        'uid': cred.user!.uid,
        'nombre': nombre,
        'email': cred.user!.email,
        'fechaRegistro': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cuenta creada correctamente")),
      );

      // Navegar después de registrar
      await _navegarDespuesLogin(cred.user!);
    } on FirebaseAuthException catch (e) {
      String msg = e.message ?? e.code;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $msg")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> iniciarSesion() async {
    setState(() => isLoading = true);
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: contrasenaController.text.trim(),
      );

      await _navegarDespuesLogin(cred.user!);
    } on FirebaseAuthException catch (e) {
      String msg = "Error al iniciar sesión.";
      if (e.code == 'user-not-found') msg = "No existe una cuenta con ese correo.";
      if (e.code == 'wrong-password') msg = "Contraseña incorrecta.";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _navegarDespuesLogin(User user) async {
    // cargamos datos de Firestore si existen
    final doc = await _firestore.collection('Usuarios').doc(user.uid).get();
    final usuarioData = doc.exists ? doc.data() : {'uid': user.uid, 'email': user.email};

    if (widget.fromCart) {
      if (widget.productos == null || widget.total == null) {
        // datos del carrito faltan: volvemos
        Navigator.pop(context);
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PagoScreen(
            usuarioData: usuarioData,
            productos: List<Map<String, dynamic>>.from(widget.productos!),
            subtotal: widget.total!,
          ),
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    nombreController.dispose();
    contrasenaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Colors.teal;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.lock, size: 80, color: Colors.teal),
              const SizedBox(height: 20),
              Text(
                isLogin ? "Iniciar sesión" : "Crear cuenta",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              if (!isLogin)
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                      labelText: "Nombre", border: OutlineInputBorder()),
                ),
              if (!isLogin) const SizedBox(height: 15),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                    labelText: "Correo", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: contrasenaController,
                obscureText: ocultarPassword,
                decoration: InputDecoration(
                  labelText: "Contraseña",
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                        ocultarPassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () =>
                        setState(() => ocultarPassword = !ocultarPassword),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: isLogin ? iniciarSesion : registrarUsuario,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: Text(
                        isLogin ? "Iniciar sesión" : "Registrarse",
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}