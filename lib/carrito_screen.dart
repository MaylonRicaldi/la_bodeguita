import 'package:flutter/material.dart';

class CarritoScreen extends StatefulWidget {
  final List<Map<String, dynamic>> initialCart;

  const CarritoScreen({Key? key, required this.initialCart}) : super(key: key);

  @override
  State<CarritoScreen> createState() => _CarritoScreenState();
}

class _CarritoScreenState extends State<CarritoScreen> {
  late List<Map<String, dynamic>> carrito;

  @override
  void initState() {
    super.initState();
    carrito = _consolidarCarrito(widget.initialCart);
  }

  // 🔹 Agrupa productos iguales sumando cantidades
  List<Map<String, dynamic>> _consolidarCarrito(List<Map<String, dynamic>> cart) {
    final Map<String, Map<String, dynamic>> agrupado = {};

    for (var item in cart) {
      final nombre = item['nombre'];
      if (agrupado.containsKey(nombre)) {
        agrupado[nombre]!['cantidad'] += 1;
        agrupado[nombre]!['total'] =
            agrupado[nombre]!['cantidad'] * agrupado[nombre]!['precio'];
      } else {
        agrupado[nombre] = {
          'nombre': nombre,
          'precio': item['precio'],
          'imagen': item['imagen'],
          'cantidad': 1,
          'total': item['precio'],
        };
      }
    }

    return agrupado.values.toList();
  }

  void _aumentarCantidad(int index) {
    setState(() {
      carrito[index]['cantidad']++;
      carrito[index]['total'] =
          carrito[index]['cantidad'] * carrito[index]['precio'];
    });
  }

  void _disminuirCantidad(int index) {
    setState(() {
      if (carrito[index]['cantidad'] > 1) {
        carrito[index]['cantidad']--;
        carrito[index]['total'] =
            carrito[index]['cantidad'] * carrito[index]['precio'];
      } else {
        carrito.removeAt(index);
      }
    });
  }

  double _calcularTotal() {
    return carrito.fold(
        0.0, (sum, item) => sum + (item['precio'] * item['cantidad']));
  }

  @override
  Widget build(BuildContext context) {
    final Color turquesa = Colors.teal.shade400;

    return Scaffold(
      appBar: AppBar(
        title: const Text(" Mi Carrito"),
        backgroundColor: turquesa,
        centerTitle: true,
      ),
      body: carrito.isEmpty
          ? const Center(
              child: Text(
                'Tu carrito está vacío ',
                style: TextStyle(fontSize: 18),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: carrito.length,
                    itemBuilder: (context, index) {
                      final item = carrito[index];
                      return Card(
                        margin:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // 🔹 Imagen del producto
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  item['imagen'] ?? '',
                                  height: 70,
                                  width: 70,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 70,
                                    width: 70,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image, size: 40),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),

                              // 🔹 Información del producto
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['nombre'],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'S/. ${item['precio'].toStringAsFixed(2)}',
                                      style: TextStyle(
                                          color: turquesa,
                                          fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Total: S/. ${item['total'].toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.black54),
                                    ),
                                  ],
                                ),
                              ),

                              // 🔹 Controles de cantidad
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline),
                                    color: Colors.redAccent,
                                    onPressed: () => _disminuirCantidad(index),
                                  ),
                                  Text(
                                    item['cantidad'].toString(),
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    color: turquesa,
                                    onPressed: () => _aumentarCantidad(index),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // 🔹 Total y botón de pagar
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Total:",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "S/. ${_calcularTotal().toStringAsFixed(2)}",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: turquesa),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: carrito.isEmpty
                            ? null
                            : () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                        "Compra realizada con éxito "),
                                    backgroundColor: turquesa,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                                setState(() => carrito.clear());
                              },
                        icon: const Icon(Icons.payment),
                        label: const Text("Poceder Pago"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: turquesa,
                          minimumSize: const Size(double.infinity, 45),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
