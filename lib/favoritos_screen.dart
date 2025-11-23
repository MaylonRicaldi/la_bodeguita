import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'producto_detalle_screen.dart';

class FavoritosScreen extends StatelessWidget {
  const FavoritosScreen({Key? key}) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.teal,
        centerTitle: true,
        elevation: 4,
        title: const Text(
          "Mis Favoritos",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: uid == null
          ? const Center(
              child: Text(
                "Inicia sesión para ver tus favoritos",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("usuarios")
                  .doc(uid)
                  .collection("favoritos")
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.teal));
                }

                final favoritos = snapshot.data!.docs;

                if (favoritos.isEmpty) {
                  return const Center(
                    child: Text(
                      "No tienes productos favoritos ❤️",
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: favoritos.length,
                  itemBuilder: (context, i) {
                    final data = favoritos[i].data() as Map<String, dynamic>;
                    final productId = favoritos[i].id;

                    final nombre = data["Nombre"] ?? "Sin nombre";
                    final precio =
                        double.tryParse(data["Precio"].toString()) ?? 0.0;
                    final imagenUrl = _formatearEnlaceDrive(data["imagen"]);

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                DetalleProductoScreen(producto: data),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: imagenUrl.isNotEmpty
                                    ? Image.network(
                                        imagenUrl,
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(Icons.broken_image,
                                                size: 50),
                                      )
                                    : Container(
                                        width: 70,
                                        height: 70,
                                        color: Colors.teal.shade50,
                                        child: const Icon(
                                          Icons.image_not_supported,
                                          color: Colors.teal,
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      nombre,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "S/. ${precio.toStringAsFixed(2)}",
                                      style: const TextStyle(
                                          color: Colors.teal,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  FirebaseFirestore.instance
                                      .collection("usuarios")
                                      .doc(uid)
                                      .collection("favoritos")
                                      .doc(productId)
                                      .delete();
                                },
                                child: const Icon(
                                  Icons.favorite,
                                  color: Colors.pinkAccent,
                                  size: 28,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
