import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:badges/badges.dart' as badges;
import 'carrito_screen.dart';
import 'producto_detalle_screen.dart';

class ProductosScreen extends StatefulWidget {
  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  final List<Map<String, dynamic>> _carrito = [];
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _animController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (!mounted) return;
    setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
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
    if (!mounted) return;
    setState(() {});
  }

  void _agregarAlCarrito(Map<String, dynamic> producto) {
    final item = {
      'nombre': producto['Nombre'] ?? 'Sin nombre',
      'precio': double.tryParse(producto['Precio'].toString()) ?? 0.0,
      'imagen': _formatearEnlaceDrive(producto['imagen']),
    };

    if (!mounted) return;
    setState(() => _carrito.add(item));

    if (!mounted) return;
    _animController.forward(from: 0);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item['nombre']} añadido al carrito 🛒'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.teal,
      ),
    );
  }

  Future<void> _abrirCarrito() async {
    if (!mounted) return;
    final updatedCart = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CarritoScreen(initialCart: _carrito),
      ),
    );

    if (!mounted) return;
    if (updatedCart != null) {
      setState(() {
        _carrito
          ..clear()
          ..addAll(updatedCart);
      });
    }
  }

  void _abrirDetalleProducto(Map<String, dynamic> producto) async {
    if (!mounted) return;
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetalleProductoScreen(producto: producto),
      ),
    );

    if (!mounted) return;
    if (resultado != null && resultado is Map<String, dynamic>) {
      _agregarAlCarrito(resultado);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color turquesa = Colors.teal.shade400;

    return SafeArea(
      child: Column(
        children: [
          // 🔹 Encabezado con carrito animado
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Catálogo",
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: turquesa)),
                ScaleTransition(
                  scale: Tween<double>(begin: 1, end: 1.3).animate(
                    CurvedAnimation(
                      parent: _animController,
                      curve: Curves.easeOutBack,
                    ),
                  ),
                  child: GestureDetector(
                    onTap: _abrirCarrito,
                    child: badges.Badge(
                      showBadge: _carrito.isNotEmpty,
                      position: badges.BadgePosition.topEnd(top: -10, end: -6),
                      badgeContent: Text(
                        _carrito.length.toString(),
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12),
                      ),
                      badgeStyle: badges.BadgeStyle(
                        badgeColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                      ),
                      child:
                          Icon(Icons.shopping_cart, size: 32, color: turquesa),
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
                hintText: 'Buscar producto disponible...',
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

          // 🔹 Rejilla de productos
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              color: turquesa,
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
                    final disponible = data['Disponibilidad'] == true ||
                        (data['Disponibilidad']?.toString().toLowerCase() ==
                            'true');
                    final nombre =
                        (data['Nombre'] ?? '').toString().toLowerCase();
                    return disponible &&
                        nombre.startsWith(_searchQuery);
                  }).toList();

                  if (productos.isEmpty) {
                    return const Center(child: Text('Sin resultados'));
                  }

                  return GridView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: productos.length,
                    itemBuilder: (context, index) {
                      final data =
                          productos[index].data() as Map<String, dynamic>;
                      final nombre = data['Nombre'] ?? 'Sin nombre';
                      final precio =
                          double.tryParse(data['Precio'].toString()) ?? 0.0;
                      final imagenUrl = _formatearEnlaceDrive(data['imagen']);

                      return GestureDetector(
                        onTap: () => _abrirDetalleProducto(data),
                        child: Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: Stack(
                            children: [
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius:
                                          const BorderRadius.vertical(
                                              top: Radius.circular(12)),
                                      child: imagenUrl.isNotEmpty
                                          ? Image.network(
                                              imagenUrl,
                                              fit: BoxFit.cover, // 🔹 Imagen adaptable
                                              width: double.infinity,
                                              errorBuilder:
                                                  (_, __, ___) => const Icon(
                                                      Icons.broken_image,
                                                      size: 80),
                                            )
                                          : const Icon(Icons.image, size: 80),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      nombre,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 8, right: 8, bottom: 6),
                                    child: ElevatedButton.icon(
                                      onPressed: () =>
                                          _agregarAlCarrito(data),
                                      icon:
                                          const Icon(Icons.add_shopping_cart),
                                      label: const Text("Agregar"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: turquesa,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'S/. ${precio.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
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
