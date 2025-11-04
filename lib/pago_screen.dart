import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';
import 'carrito_global.dart'; // ✅ Para limpiar carrito local

class PagoScreen extends StatefulWidget {
  final Map<String, dynamic>? usuarioData;
  final List<Map<String, dynamic>> productos;
  final double subtotal;

  const PagoScreen({
    Key? key,
    required this.usuarioData,
    required this.productos,
    required this.subtotal,
  }) : super(key: key);

  @override
  State<PagoScreen> createState() => _PagoScreenState();
}

class _PagoScreenState extends State<PagoScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  bool _processing = false;

  double get igv => widget.subtotal * 0.18;
  double get totalConIgv => widget.subtotal + igv;

  Future<void> _mostrarConfirmacionPago() async {
    final confirmar = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          "Confirmar Pago",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text("¿Deseas confirmar tu pedido y proceder con el pago?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar", style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Confirmar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      _confirmarPedido();
    }
  }

  Future<void> _confirmarPedido() async {
    if (_auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Debes iniciar sesión para confirmar el pedido")),
      );
      return;
    }

    setState(() => _processing = true);

    try {
      final uid = _auth.currentUser!.uid;

      final pedidoData = {
        'fecha': FieldValue.serverTimestamp(),
        'subtotal': widget.subtotal,
        'igv': igv,
        'total': totalConIgv,
        'estado': 'Pendiente',
        'productos': widget.productos,
      };

      // ✅ Guardar pedido
      await _firestore.collection('Usuarios').doc(uid).collection('Pedidos').add(pedidoData);

      // ✅ Vaciar carrito Firestore
      final carrito = await _firestore
          .collection('Usuarios')
          .doc(uid)
          .collection('Carrito')
          .get();

      for (var doc in carrito.docs) {
        await doc.reference.delete();
      }

      // ✅ Vaciar carrito LOCAL
      carritoGlobal.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Pedido confirmado 🎉"),
          backgroundColor: Colors.teal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(10),
        ),
      );

      final usuarioDoc = await _firestore.collection('Usuarios').doc(uid).get();
      final usuarioData = usuarioDoc.exists ? usuarioDoc.data() : {'uid': uid};

      // ✅ Volver a Home y refrescar todo
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => HomePage(initialIndex: 0, usuarioData: usuarioData),
        ),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = widget.usuarioData ?? {};
    const turquesa = Colors.teal;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: turquesa,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Resumen del Pedido",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // ---------------- USER CARD ----------------
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: turquesa,
                    child: const Icon(Icons.person, size: 32, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(usuario['nombre'] ?? 'Cliente',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(usuario['email'] ?? '',
                          style: const TextStyle(color: Colors.black54)),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ---------------- PRODUCT LIST ----------------
            Expanded(
              child: ListView.builder(
                itemCount: widget.productos.length,
                itemBuilder: (_, i) {
                  final p = widget.productos[i];
                  final nombre = p['nombre'];
                  final cantidad = p['cantidad'];
                  final precio = (p['precio']).toDouble();
                  final imagen = p['imagen'] ?? p['url'] ?? "";

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
                    ),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: imagen.isNotEmpty
                            ? Image.network(imagen, width: 55, height: 55, fit: BoxFit.cover)
                            : Container(
                                width: 55,
                                height: 55,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.image_not_supported, color: Colors.grey),
                              ),
                      ),
                      title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text("Cantidad: $cantidad"),
                      trailing: Text(
                        "S/. ${(precio * cantidad).toStringAsFixed(2)}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                },
              ),
            ),

            // ---------------- TOTALS ----------------
            Column(
              children: [
                _rowTotal("Subtotal", widget.subtotal),
                _rowTotal("IGV 18%", igv),
                const Divider(),
                _rowTotal("Total", totalConIgv, bold: true, color: turquesa),
              ],
            ),

            const SizedBox(height: 14),

            // ---------------- BUTTON ----------------
            ElevatedButton(
              onPressed: _processing ? null : _mostrarConfirmacionPago,
              style: ElevatedButton.styleFrom(
                backgroundColor: turquesa,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _processing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Confirmar Pedido", style: TextStyle(fontSize: 18)),
            )
          ],
        ),
      ),
    );
  }

  Widget _rowTotal(String label, double value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.w400)),
          Text(
            "S/. ${value.toStringAsFixed(2)}",
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w400,
              fontSize: bold ? 17 : 14,
              color: color,
            ),
          )
        ],
      ),
    );
  }
}
