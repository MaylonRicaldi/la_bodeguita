import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  bool _logueado = false;
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  final Color turquesa = Colors.teal.shade400;

  final String _adminCorreo = 'admin@continental.edu.pe';
  final String _adminPass = '123456';

  final GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();

  void _iniciarSesion() {
    if (_correoController.text.trim() == _adminCorreo &&
        _passController.text == _adminPass) {
      setState(() {
        _logueado = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Correo o contraseña inválida'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _onSearchChanged() {
    if (!mounted) return;
    setState(() {
      _searchQuery = quitarAcentos(_searchController.text.trim().toLowerCase());
    });
  }

  String quitarAcentos(String texto) {
    const acentos = {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'Á': 'A',
      'É': 'E',
      'Í': 'I',
      'Ó': 'O',
      'Ú': 'U',
      'ñ': 'n',
      'Ñ': 'N'
    };
    return texto.split('').map((c) => acentos[c] ?? c).join();
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

  Future<void> _actualizarProducto(
      String docId, bool disponibilidad, int stock) async {
    await FirebaseFirestore.instance.collection('productos').doc(docId).update({
      'Disponibilidad': disponibilidad,
      'Stock': stock,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Producto actualizado'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _correoController.dispose();
    _passController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      backgroundColor: turquesa,
      centerTitle: true,
      title: Text(
        _logueado ? "Administrador" : "Login",
        style: TextStyle(
          fontSize: 22,               // estilo Catálogo
          fontWeight: FontWeight.bold,
          color: Colors.white,        // color blanco
        ),
      ),
    ),
      body: SafeArea(
        child: _logueado
            ? Column(
                children: [
                  // Buscador
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

                  Expanded(
                    child: RefreshIndicator(
                      key: _refreshKey,
                      onRefresh: () async {
                        setState(() {});
                      },
                      color: turquesa,
                      displacement: 40,
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('productos')
                            .orderBy('Nombre')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          // Filtrado por búsqueda
                          final productos = snapshot.data!.docs.where((doc) {
                            final data =
                                doc.data() as Map<String, dynamic>;
                            final nombre = quitarAcentos(
                                (data['Nombre'] ?? '').toString().toLowerCase());
                            return nombre.startsWith(_searchQuery);
                          }).toList();

                          if (productos.isEmpty)
                            return const Center(child: Text("Sin resultados"));

                          return GridView.builder(
                            padding: const EdgeInsets.all(10),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.65,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: productos.length,
                            itemBuilder: (context, index) {
                              final data =
                                  productos[index].data() as Map<String, dynamic>;
                              final docId = productos[index].id;
                              final nombre = data['Nombre'] ?? 'Sin nombre';
                              final precio = double.tryParse(
                                      data['Precio'].toString()) ??
                                  0.0;
                              final imagen =
                                  _formatearEnlaceDrive(data['imagen']);
                              final disponibilidad =
                                  data['Disponibilidad'] ?? true;
                              final stock = data['Stock'] ?? 0;

                              return Card(
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: const BorderRadius.vertical(
                                            top: Radius.circular(12)),
                                        child: imagen.isNotEmpty
                                            ? Image.network(
                                                imagen,
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                errorBuilder: (_, __, ___) =>
                                                    Image.asset(
                                                        'assets/logo_producto.png'),
                                              )
                                            : Image.asset(
                                                'assets/logo_producto.png'),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Text(
                                            nombre,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                              'Precio: S/. ${precio.toStringAsFixed(2)}'),
                                          const SizedBox(height: 6),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  const Text("Disp: "),
                                                  Switch(
                                                    value: disponibilidad,
                                                    onChanged: (val) {
                                                      _actualizarProducto(
                                                          docId, val, stock);
                                                    },
                                                    activeColor: turquesa,
                                                  ),
                                                ],
                                              ),
                                              SizedBox(
                                                width: 50,
                                                child: TextFormField(
                                                  initialValue: stock.toString(),
                                                  keyboardType:
                                                      TextInputType.number,
                                                  decoration:
                                                      const InputDecoration(
                                                    isDense: true,
                                                    contentPadding:
                                                        EdgeInsets.symmetric(
                                                            vertical: 6,
                                                            horizontal: 8),
                                                    border: OutlineInputBorder(),
                                                  ),
                                                  onFieldSubmitted: (val) {
                                                    final nuevoStock =
                                                        int.tryParse(val) ?? stock;
                                                    _actualizarProducto(docId,
                                                        disponibilidad, nuevoStock);
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextField(
                      controller: _correoController,
                      decoration: InputDecoration(
                        labelText: "Correo",
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Contraseña",
                        prefixIcon: const Icon(Icons.lock),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _iniciarSesion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: turquesa,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          "Iniciar Sesión",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
