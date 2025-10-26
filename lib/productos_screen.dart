import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:badges/badges.dart' as badges;
import 'package:animate_do/animate_do.dart';

class ProductosScreen extends StatefulWidget {
  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  final List<Map<String, dynamic>> _carrito = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
    });
  }

  String _formatearEnlaceDrive(String? url) {
    if (url == null || url.isEmpty) return "";
    final regex = RegExp(r'/d/([^/]+)/');
    final match = regex.firstMatch(url);
    if (match != null) {
      final id = match.group(1);
      return "https://drive.google.com/uc?export=view&id=$id";
    }
    return url;
  }

  Future<void> _onRefresh() async {
    setState(() {});
  }

  void _agregarAlCarrito(Map<String, dynamic> producto) {
    setState(() {
      _carrito.add(producto);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${producto['Nombre']} añadido al carrito'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _abrirCarrito() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        if (_carrito.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: Text('Tu carrito está vacío 🛒')),
          );
        }
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '🛍 Carrito de Compras',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: _carrito.length,
                  itemBuilder: (context, index) {
                    final producto = _carrito[index];
                    return ListTile(
                      title: Text(producto['Nombre'] ?? 'Sin nombre'),
                      subtitle:
                          Text('S/. ${producto['Precio'] ?? 0}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _carrito.removeAt(index);
                          });
                          Navigator.pop(context);
                          _abrirCarrito();
                        },
                      ),
                    );
                  },
                ),
              ),
              const Divider(),
              Text(
                'Total: S/. ${_carrito.fold<double>(0, (sum, item) => sum + (item['Precio'] ?? 0))}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // 🔹 Título superior con carrito
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Productos",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
                FadeInDown(
                  child: GestureDetector(
                    onTap: _abrirCarrito,
                    child: badges.Badge(
                      showBadge: _carrito.isNotEmpty,
                      position: badges.BadgePosition.topEnd(top: -10, end: -6),
                      badgeContent: Text(
                        _carrito.length.toString(),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      badgeStyle: const badges.BadgeStyle(
                        badgeColor: Colors.redAccent,
                        padding:
                            EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      ),
                      child: const Icon(Icons.shopping_cart,
                          size: 32, color: Colors.blue),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 🔹 Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar producto...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          FocusScope.of(context).unfocus();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),

          // 🔹 Lista de productos 
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              color: Colors.blue,
              displacement: 40,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('productos')
                    .orderBy('Nombre')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No hay productos'));
                  }

                  final productos = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final nombre =
                        (data['Nombre'] ?? '').toString().toLowerCase();
                    return nombre.contains(_searchQuery);
                  }).toList();

                  if (productos.isEmpty) {
                    return const Center(child: Text('Sin resultados'));
                  }

                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: productos.length,
                    itemBuilder: (context, index) {
                      final data =
                          productos[index].data() as Map<String, dynamic>;

                      final nombre = data['Nombre'] ?? 'Sin nombre';
                      final marca = data['Marca'] ?? 'Sin marca';
                      final cantidad = data['Cantidad'] ?? '-';
                      final precio = data['Precio'] ?? 0;
                      final stock = data['Stock'] ?? 0;
                      final disponible = data['Disponibilidad'] ?? false;
                      final imagenUrl =
                          _formatearEnlaceDrive(data['imagen']);

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: imagenUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    imagenUrl,
                                    width: 65,
                                    height: 65,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(Icons.image, size: 50),
                          title: Text(
                            nombre,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Marca: $marca'),
                              Text('Cantidad: $cantidad'),
                              Text('Precio: S/. $precio'),
                              Text('Stock: $stock'),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    disponible
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color: disponible
                                        ? Colors.green
                                        : Colors.red,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    disponible ? 'Disponible' : 'Agotado',
                                    style: TextStyle(
                                      color: disponible
                                          ? Colors.green
                                          : Colors.red,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.add_shopping_cart,
                                color: Colors.blue),
                            onPressed: () => _agregarAlCarrito(data),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
