import 'package:flutter/material.dart';
import 'carrito_global.dart';
import 'auth_screen.dart';
import 'pago_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CarritoScreen extends StatefulWidget {
  final List<Map<String, dynamic>> initialCart;
  const CarritoScreen({Key? key, required this.initialCart}) : super(key: key);

  @override
  State<CarritoScreen> createState() => _CarritoScreenState();
}

class _CarritoScreenState extends State<CarritoScreen> {
  late List<Map<String, dynamic>> _cart;

  @override
  void initState() {
    super.initState();
    _cart = List.from(widget.initialCart);
  }

  void _actualizarCantidad(int index, int nuevaCantidad) {
    setState(() {
      if (nuevaCantidad <= 0) {
        _cart.removeAt(index);
      } else {
        _cart[index]['cantidad'] = nuevaCantidad;
        _cart[index]['total'] =
            nuevaCantidad * (_cart[index]['precio'] ?? 0.0);
      }
      carritoGlobal = List.from(_cart);
    });
  }

  double _calcularTotal() {
    return _cart.fold(0.0, (sum, item) => sum + (item['total'] ?? 0.0));
  }

  void _vaciarCarrito() {
    setState(() {
      _cart.clear();
      carritoGlobal.clear();
    });
  }

  void _procederAlPago() async {
    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      // 🔐 Si no hay sesión → ir al login, pasando carrito y total
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AuthScreen(
            fromCart: true,
            total: _calcularTotal(),
            productos: _cart,
          ),
        ),
      );
    } else {
      // ✅ Si hay sesión → ir directo al pago
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PagoScreen(
            usuarioData: {
              'uid': usuario.uid,
              'email': usuario.email ?? '',
            },
            productos: _cart,
            subtotal: _calcularTotal(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color turquesa = Colors.teal.shade400;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mi Carrito"),
        backgroundColor: turquesa,
        actions: [
          if (_cart.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_forever),
              onPressed: _vaciarCarrito,
            ),
        ],
      ),
      body: _cart.isEmpty
          ? const Center(
              child: Text(
                "Tu carrito está vacío ",
                style: TextStyle(fontSize: 18),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _cart.length,
                    itemBuilder: (context, i) {
                      final item = _cart[i];
                      final nombre = item['nombre'] ?? 'Producto';
                      final imagen = item['imagen'] ?? '';
                      final precio = item['precio'] ?? 0.0;
                      final cantidad = item['cantidad'] ?? 1;
                      final total = item['total'] ?? precio;

                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: imagen.isNotEmpty
                                    ? Image.network(
                                        imagen,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(Icons.image, size: 60),
                                      )
                                    : const Icon(Icons.image, size: 60),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      nombre,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                    const SizedBox(height: 4),
                                    Text('S/. ${precio.toStringAsFixed(2)} c/u',
                                        style: const TextStyle(
                                            color: Colors.grey)),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle,
                                              color: Colors.red),
                                          onPressed: () => _actualizarCantidad(
                                              i, cantidad - 1),
                                        ),
                                        Text('$cantidad',
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold)),
                                        IconButton(
                                          icon: const Icon(Icons.add_circle,
                                              color: Colors.green),
                                          onPressed: () => _actualizarCantidad(
                                              i, cantidad + 1),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'S/. ${total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 5,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Total:",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('S/. ${_calcularTotal().toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton.icon(
                          onPressed:
                              _cart.isEmpty ? null : () => _procederAlPago(),
                          icon: const Icon(Icons.payment),
                          label: const Text("Proceder al pago"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: turquesa,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
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
