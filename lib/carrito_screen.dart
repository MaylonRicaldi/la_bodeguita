import 'package:flutter/material.dart';

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

  void _removeAt(int index) {
    setState(() => _cart.removeAt(index));
  }

  void _clearAll() {
    setState(() => _cart.clear());
  }

  double _total() {
    double t = 0;
    for (final item in _cart) {
      final p = item['precio'];
      if (p is num) t += p.toDouble();
      else if (p is String) t += double.tryParse(p) ?? 0;
    }
    return t;
  }

  // Al cerrar devolvemos la lista actualizada
  Future<bool> _onWillPop() async {
    Navigator.pop(context, _cart);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Carrito'),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_forever),
              onPressed: _cart.isEmpty ? null : _clearAll,
            )
          ],
        ),
        body: _cart.isEmpty
            ? const Center(child: Text('El carrito está vacío'))
            : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: _cart.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final item = _cart[i];
                  final nombre = item['nombre'] ?? '-';
                  final precio = item['precio'] ?? 0;
                  final imagen = (item['imagen'] ?? '').toString();
                  return Card(
                    child: ListTile(
                      leading: imagen.isNotEmpty
                          ? Image.network(imagen, width: 56, height: 56, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image))
                          : const Icon(Icons.image),
                      title: Text(nombre),
                      subtitle: Text('S/. ${precio.toString()}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () => _removeAt(i),
                      ),
                    ),
                  );
                },
              ),
        bottomNavigationBar: _cart.isEmpty
            ? null
            : Container(
                padding: const EdgeInsets.all(12),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total: S/. ${_total().toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Compra simulada ✅')));
                      },
                      child: const Text('Pagar'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
