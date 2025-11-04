import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:badges/badges.dart' as badges;
import 'carrito_screen.dart';
import 'producto_detalle_screen.dart';
import 'carrito_global.dart';

class ProductosScreen extends StatefulWidget {
  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen>
    with SingleTickerProviderStateMixin {

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  // ✅ Quitar tildes para buscar
  String quitarAcentos(String texto) {
    const acentos = {
      'á':'a','é':'e','í':'i','ó':'o','ú':'u',
      'Á':'A','É':'E','Í':'I','Ó':'O','Ú':'U',
      'ñ':'n','Ñ':'N'
    };
    return texto.split('').map((c) => acentos[c] ?? c).join();
  }

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
    setState(() => _searchQuery = quitarAcentos(_searchController.text.trim().toLowerCase()));
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

  int _totalItemsEnCarrito() {
    return carritoGlobal.fold<int>(0, (sum, it) => sum + ((it['cantidad'] ?? 1) as int));
  }

  void _agregarAlCarrito(Map<String, dynamic> producto) {
    final nombre = producto['Nombre'] ?? 'Sin nombre';
    final precio = double.tryParse(producto['Precio'].toString()) ?? 0.0;
    final imagen = _formatearEnlaceDrive(producto['imagen']);

    final index = carritoGlobal.indexWhere((item) => item['nombre'] == nombre);

    if (index != -1) {
      carritoGlobal[index]['cantidad'] = (carritoGlobal[index]['cantidad'] ?? 1) + 1;
      carritoGlobal[index]['total'] =
          carritoGlobal[index]['cantidad'] * carritoGlobal[index]['precio'];
    } else {
      carritoGlobal.add({
        'nombre': nombre,
        'precio': precio,
        'imagen': imagen,
        'cantidad': 1,
        'total': precio,
      });
    }

    if (!mounted) return;

    _animController.forward(from: 0);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$nombre añadido al carrito'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.teal,
      ),
    );

    setState(() {});
  }

  Future<void> _abrirCarrito() async {
    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CarritoScreen(initialCart: carritoGlobal),
      ),
    );

    if (!mounted) return;
    setState(() {});
  }

  void _abrirDetalleProducto(Map<String, dynamic> producto) async {
    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetalleProductoScreen(producto: producto),
      ),
    );

    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final Color turquesa = Colors.teal.shade400;

    return SafeArea(
      child: Column(
        children: [

          // ✅ Encabezado
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
                    CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
                  ),
                  child: GestureDetector(
                    onTap: _abrirCarrito,
                    child: badges.Badge(
                      showBadge: _totalItemsEnCarrito() > 0,
                      position: badges.BadgePosition.topEnd(top: -10, end: -6),
                      badgeContent: Text(
                        _totalItemsEnCarrito().toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      badgeStyle: badges.BadgeStyle(
                        badgeColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      ),
                      child: Icon(Icons.shopping_cart, size: 32, color: turquesa),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ✅ Buscador
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

          // ✅ Lista de Productos
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
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  final productos = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final nombre = quitarAcentos((data['Nombre'] ?? '').toString().toLowerCase());
                    final disponible = data['Disponibilidad'] == true ||
                        data['Disponibilidad'].toString().toLowerCase() == 'true';
                    return disponible && nombre.startsWith(_searchQuery);
                  }).toList();

                  if (productos.isEmpty) return const Center(child: Text("Sin resultados"));

                  return GridView.builder(
                    key: const PageStorageKey('grid_productos'), // ✅ Mantiene la posición del scroll
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: productos.length,
                    itemBuilder: (context, index) {
                      final data = productos[index].data() as Map<String, dynamic>;
                      final nombre = data['Nombre'] ?? 'Sin nombre';
                      final precio = double.tryParse(data['Precio'].toString()) ?? 0.0;
                      final imagenUrl = _formatearEnlaceDrive(data['imagen']);

                      return GestureDetector(
                        onTap: () => _abrirDetalleProducto(data),
                        child: Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Stack(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                      child: imagenUrl.isNotEmpty
                                          ? Image.network(
                                              imagenUrl,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              errorBuilder: (_, __, ___) =>
                                                  const Icon(Icons.broken_image, size: 80),
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
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8, right: 8, bottom: 6),
                                    child: ElevatedButton.icon(
                                      onPressed: () => _agregarAlCarrito(data),
                                      icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
                                      label: const Text(
                                        "Agregar",
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),

                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.teal,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'S/. ${precio.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        color: Colors.white, fontWeight: FontWeight.bold),
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
