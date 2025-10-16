import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductosScreen extends StatefulWidget {
  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  final int _limitIncrement = 10;
  int _limit = 10;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      setState(() {
        _limit += _limitIncrement;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('productos')
          .limit(_limit)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error al cargar productos'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final productos = snapshot.data!.docs;

        if (productos.isEmpty) {
          return const Center(child: Text('No hay productos'));
        }

        return ListView.builder(
          controller: _scrollController,
          itemCount: productos.length,
          itemBuilder: (context, index) {
            final data = productos[index].data() as Map<String, dynamic>;

            final nombre = data['nombre'] ?? 'Sin nombre';
            final precio = data['precio'] ?? 0;
            final imagenUrl = data['imagen']; // 🔥 Aquí traes el enlace de Drive

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              elevation: 3,
              child: ListTile(
                leading: imagenUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imagenUrl,
                          width: 55,
                          height: 55,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.image_not_supported, size: 40),
                        ),
                      )
                    : const Icon(Icons.image, size: 40),
                title: Text(nombre,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Precio: S/. $precio'),
              ),
            );
          },
        );
      },
    );
  }
}
