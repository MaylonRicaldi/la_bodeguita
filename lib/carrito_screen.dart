import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'carrito_global.dart';
import 'auth_screen.dart';

class CarritoScreen extends StatefulWidget {
  final List<Map<String, dynamic>> initialCart;
  const CarritoScreen({Key? key, required this.initialCart}) : super(key: key);

  @override
  State<CarritoScreen> createState() => _CarritoScreenState();
}

class _CarritoScreenState extends State<CarritoScreen> {
  late List<Map<String, dynamic>> _cart;
  bool _processing = false;
  User? _usuario;
  String? _metodoPagoSeleccionado;

  @override
  void initState() {
    super.initState();
    _cart = List.from(widget.initialCart);
    _usuario = FirebaseAuth.instance.currentUser;

     _loadCartFromFirestore(); 
  }

  void _actualizarCantidad(int index, int nuevaCantidad) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) return;

    setState(() {
      if (nuevaCantidad <= 0) {
        FirebaseFirestore.instance
            .collection("Usuarios")
            .doc(uid)
            .collection("Carrito")
            .doc(_cart[index]["id"])
            .delete();

        _cart.removeAt(index);
      } else {
        _cart[index]['cantidad'] = nuevaCantidad;
        _cart[index]['total'] = nuevaCantidad * (_cart[index]['precio'] ?? 0.0);

        FirebaseFirestore.instance
            .collection("Usuarios")
            .doc(uid)
            .collection("Carrito")
            .doc(_cart[index]["id"])
            .update({
          "cantidad": nuevaCantidad,
          "total": _cart[index]["total"],
        });
      }

      carritoGlobal = List.from(_cart);
    });
  }


  double _calcularTotal() => _cart.fold(0.0, (sum, item) => sum + (item['total'] ?? 0.0));
  double _calcularIgv() => _calcularTotal() * 0.18;
  double _calcularSubtotal() => _calcularTotal() - _calcularIgv();

  void _vaciarCarrito() {
    setState(() {
      _cart.clear();
      carritoGlobal.clear();
    });
  }

    Future<void> _loadCartFromFirestore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection("Usuarios")
        .doc(uid)
        .collection("Carrito")
        .get();


    if (_cart.isNotEmpty) return;


    setState(() {
      _cart = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          "id": doc.id,
          "nombre": data["nombre"],
          "precio": data["precio"],
          "cantidad": data["cantidad"],
          "total": (data["precio"] ?? 0.0) * (data["cantidad"] ?? 1),
          "imagen": data["imagen"],
        };
      }).toList();

    });

    carritoGlobal = List.from(_cart);
  }


  Future<void> _confirmarPago() async {
    if (_usuario == null) return;

    if (_metodoPagoSeleccionado == null || _metodoPagoSeleccionado == "No hay método de pago") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, escoge un método de pago")),
      );
      return;
    }

    setState(() => _processing = true);

    try {
      final uid = _usuario!.uid;
      final pedidoData = {
        'fecha': FieldValue.serverTimestamp(),
        'subtotal': _calcularSubtotal(),
        'igv': _calcularIgv(),
        'total': _calcularTotal(),
        'estado': 'Pendiente',
        'metodoPago': _metodoPagoSeleccionado,
        'productos': _cart,
      };

      await FirebaseFirestore.instance
          .collection('Usuarios')
          .doc(uid)
          .collection('Pedidos')
          .add(pedidoData);

      final carrito = await FirebaseFirestore.instance
          .collection('Usuarios')
          .doc(uid)
          .collection('Carrito')
          .get();

      for (var doc in carrito.docs) await doc.reference.delete();

      carritoGlobal.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pedido confirmado 🎉")),
      );

      Navigator.pop(context, "reload");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  void _procesoPago() async {
    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AuthScreen(
            fromCart: true,
            total: _calcularTotal(),
            productos: _cart,
          ),
        ),
      );

      setState(() {
        _usuario = FirebaseAuth.instance.currentUser;
      });
      return;
    }

    _confirmarPago();
  }

  Widget _iconoMetodoPago(String metodo) {
    switch (metodo) {
      case 'Tarjeta de Crédito':
        return const Icon(Icons.credit_card, color: Colors.teal, size: 28);
      case 'Transferencia Bancaria':
        return const Icon(Icons.account_balance, color: Colors.teal, size: 28);
      case 'PayPal':
        return const Icon(Icons.phone_android, color: Colors.teal, size: 28);
      case 'No hay método de pago':
        return const Icon(Icons.close, color: Colors.red, size: 28);
      default:
        return const SizedBox(width: 28, height: 28);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color turquesa = Colors.teal.shade400;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: turquesa,
        elevation: 6,
        centerTitle: true,
        title: const Text(
          "Resumen de Pedido",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_cart.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.white),
              onPressed: _vaciarCarrito,
            ),
        ],
      ),
      body: _cart.isEmpty
          ? const Center(
              child: Text(
                "Tu carrito está vacío",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : Column(
              children: [
                // ✅ BIENVENIDA CON NOMBRE DEL USUARIO
                if (_usuario != null)
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('Usuarios')
                        .doc(_usuario!.uid)
                        .get(),
                    builder: (context, snapshot) {
                      String nombreUsuario = "Usuario";
                      
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final data = snapshot.data!.data() as Map<String, dynamic>?;
                        nombreUsuario = data?['nombre'] ?? _usuario!.displayName ?? "Usuario";
                      } else if (_usuario!.displayName != null) {
                        nombreUsuario = _usuario!.displayName!;
                      }

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.waving_hand,
                              color: Colors.amber,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Bienvenido $nombreUsuario",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 8),

                // ✅ CORREGIDO: Método de pago con Row que no se desborda
                if (_usuario != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _metodoPagoSeleccionado,
                            hint: const Text(
                              "Selecciona un método de pago",
                              style: TextStyle(fontSize: 14),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'No hay método de pago',
                                child: Text('No hay método de pago'),
                              ),
                              DropdownMenuItem(
                                value: 'Tarjeta de Crédito',
                                child: Text('Tarjeta de Crédito'),
                              ),
                              DropdownMenuItem(
                                value: 'Transferencia Bancaria',
                                child: Text('Transferencia Bancaria'),
                              ),
                              DropdownMenuItem(
                                value: 'PayPal',
                                child: Text('PayPal'),
                              ),
                            ],
                            onChanged: (valor) {
                              setState(() => _metodoPagoSeleccionado = valor);
                            },
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            isExpanded: true,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: _metodoPagoSeleccionado != null
                                ? _iconoMetodoPago(_metodoPagoSeleccionado!)
                                : const Icon(
                                    Icons.payment,
                                    color: Colors.grey,
                                    size: 24,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 8),

                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: _cart.length,
                    itemBuilder: (context, i) {
                      final item = _cart[i];
                      final nombre = item['nombre'] ?? 'Producto';
                      final imagen = item['imagen'] ?? '';
                      final precio = item['precio'] ?? 0.0;
                      final cantidad = item['cantidad'] ?? 1;
                      final total = item['total'] ?? precio;

                      return Card(
                        elevation: 4,
                        shadowColor: Colors.black26,
                        margin: const EdgeInsets.only(bottom: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: imagen.isNotEmpty
                                    ? Image.network(
                                        imagen,
                                        width: 85,
                                        height: 85,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        width: 85,
                                        height: 85,
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.image, size: 40),
                                      ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      nombre,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 17,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'S/. ${precio.toStringAsFixed(2)} c/u',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        _circleBtn(
                                          icon: Icons.remove,
                                          color: Colors.redAccent,
                                          onTap: () =>
                                              _actualizarCantidad(i, cantidad - 1),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10),
                                          child: Text(
                                            '$cantidad',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        _circleBtn(
                                          icon: Icons.add,
                                          color: Colors.green,
                                          onTap: () =>
                                              _actualizarCantidad(i, cantidad + 1),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'S/. ${total.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                  color: turquesa,
                                ),
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
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(18)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _rowTotal("Subtotal", _calcularSubtotal()),
                      const SizedBox(height: 6),
                      _rowTotal("IGV (18%)", _calcularIgv()),
                      const Divider(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "TOTAL",
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            "S/. ${_calcularTotal().toStringAsFixed(2)}",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: turquesa,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        height: 55,
                        child: ElevatedButton(
                          onPressed:
                              _cart.isEmpty || _processing ? null : _procesoPago,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: turquesa,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 4,
                          ),
                          child: _processing
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text(
                                  "Confirmar Pedido",
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
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

  Widget _rowTotal(String label, double value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
        ),
        Text(
          "S/. ${value.toStringAsFixed(2)}",
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _circleBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}