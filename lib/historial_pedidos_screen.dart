import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistorialPedidosScreen extends StatelessWidget {
  const HistorialPedidosScreen({Key? key}) : super(key: key);

  Future<String> _obtenerNombreUsuario() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return "Usuario";

      final snap = await FirebaseFirestore.instance
          .collection('Usuarios')
          .doc(uid)
          .get();

      if (snap.exists && snap.data()!.containsKey('nombre')) {
        return snap.data()!['nombre'] ?? "Usuario";
      }

      // Si no hay nombre en Firestore, usar el displayName de Firebase Auth
      return FirebaseAuth.instance.currentUser?.displayName ?? "Usuario";
    } catch (e) {
      return "Usuario";
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 4,
        backgroundColor: Colors.teal,
        centerTitle: true,
        title: const Text(
          "Historial de Pedidos",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: uid == null
          ? const Center(child: Text("Inicia sesión para ver tus pedidos"))
          : FutureBuilder<String>(
              future: _obtenerNombreUsuario(),
              builder: (context, nombreSnapshot) {
                final nombreUsuario = nombreSnapshot.data ?? "Usuario";

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('Usuarios')
                      .doc(uid)
                      .collection('Pedidos')
                      .orderBy('fecha', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.teal),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.shopping_bag_outlined,
                              size: 80,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Hola $nombreUsuario 👋",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "No tienes pedidos aún 🛒",
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }

                    final pedidos = snapshot.data!.docs;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            "Hola $nombreUsuario 👋",
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            itemCount: pedidos.length,
                            itemBuilder: (_, i) {
                              final pedido =
                                  pedidos[i].data() as Map<String, dynamic>;
                              final total = pedido['total'] ?? 0.0;
                              final fecha =
                                  (pedido['fecha'] as Timestamp?)?.toDate();
                              final numeroPedido = pedidos.length - i;

                              return GestureDetector(
                                onTap: () => _mostrarDetallePedido(
                                    context, pedido, numeroPedido),
                                child: Card(
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(18),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 52,
                                          height: 52,
                                          decoration: BoxDecoration(
                                            color: Colors.teal.shade100,
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                          child: const Icon(
                                            Icons.receipt_long,
                                            color: Colors.teal,
                                            size: 28,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Pedido $numeroPedido",
                                                style: const TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                fecha != null
                                                    ? "${fecha.day}/${fecha.month}/${fecha.year}   ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}"
                                                    : "Fecha no disponible",
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          "S/. ${total.toStringAsFixed(2)}",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.teal,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
    );
  }

  // ====================== DETALLE DEL PEDIDO MEJORADO ======================

  void _mostrarDetallePedido(
      BuildContext context, Map<String, dynamic> pedido, int numeroPedido) {
    final productos = pedido['productos'] as List<dynamic>;
    final total = pedido['total'] ?? 0.0;
    final subtotal = pedido['subtotal'] ?? 0.0;
    final igv = pedido['igv'] ?? 0.0;
    final fecha = (pedido['fecha'] as Timestamp?)?.toDate();
    final direccion = pedido['direccion'] ?? "Por definir";
    final metodoPago = pedido['metodoPago'] ?? "Efectivo";
    final estado = pedido['estado'] ?? "Pendiente";

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: controller,
            children: [
              // Handle superior
              Center(
                child: Container(
                  width: 55,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Título
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.receipt_long,
                      color: Colors.teal,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Pedido #$numeroPedido",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          fecha != null
                              ? "${fecha.day}/${fecha.month}/${fecha.year} - ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}"
                              : "Fecha no disponible",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const Divider(height: 30),

              // Información del pedido (SIN DIRECCIÓN)
              _seccionInfo("💳 Método de pago", metodoPago),
              const SizedBox(height: 12),
              _seccionInfo(
                "📊 Estado",
                estado,
                colorTexto: _obtenerColorEstado(estado),
              ),

              const Divider(height: 30),

              // Productos
              const Text(
                "🛍️ Productos",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              ...productos.map((p) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: p['imagen'] != null
                            ? Image.network(
                                p['imagen'],
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.teal.shade50,
                                  child: const Icon(Icons.image_not_supported,
                                      color: Colors.teal),
                                ),
                              )
                            : Container(
                                width: 60,
                                height: 60,
                                color: Colors.teal.shade50,
                                child: const Icon(Icons.image_not_supported,
                                    color: Colors.teal),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p['nombre'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Cantidad: ${p['cantidad']}",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        "S/. ${(p['precio'] * p['cantidad']).toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),

              const Divider(height: 30),

              // Total desglosado
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _filaTotal("Subtotal:", subtotal, esSubtotal: true),
                    const SizedBox(height: 8),
                    _filaTotal("IGV (18%):", igv, esSubtotal: true),
                    const Divider(height: 20),
                    _filaTotal("Total:", total, esTotal: true),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Botón cerrar
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Cerrar",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _seccionInfo(String titulo, String valor, {Color? colorTexto}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Flexible(
            child: Text(
              valor,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: colorTexto ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _obtenerColorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'entregado':
        return Colors.green;
      case 'en camino':
        return Colors.orange;
      case 'pendiente':
        return Colors.blue;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _filaTotal(String label, double valor,
      {bool esSubtotal = false, bool esTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: esTotal ? 18 : 15,
            fontWeight: esTotal ? FontWeight.bold : FontWeight.w500,
            color: esTotal ? Colors.black : Colors.grey.shade700,
          ),
        ),
        Text(
          "S/. ${valor.toStringAsFixed(2)}",
          style: TextStyle(
            fontSize: esTotal ? 22 : 16,
            fontWeight: FontWeight.bold,
            color: esTotal ? Colors.teal : Colors.black87,
          ),
        ),
      ],
    );
  }
}