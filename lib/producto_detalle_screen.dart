import 'package:flutter/material.dart';

class DetalleProductoScreen extends StatelessWidget {
  final Map<String, dynamic> producto;

  const DetalleProductoScreen({Key? key, required this.producto})
      : super(key: key);

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
    final Color turquesa = Colors.teal.shade400;

    final String nombre = producto['Nombre'] ?? 'Sin nombre';

    // 🔹 Precio seguro
    final dynamic precioRaw = producto['Precio'] ?? 0;
    final double precio = (precioRaw is num)
        ? precioRaw.toDouble()
        : double.tryParse(precioRaw.toString()) ?? 0;

    // 🔹 Cantidad segura
    final dynamic cantidadRaw = producto['Cantidad'] ?? '';
    final String cantidad = cantidadRaw.toString();

    // 🔹 Disponibilidad adaptable (puede ser texto o booleano)
    final dynamic disponibilidadRaw = producto['Disponibilidad'];
    final String disponibilidad = (disponibilidadRaw is bool)
        ? (disponibilidadRaw ? 'Disponible' : 'No disponible')
        : (disponibilidadRaw?.toString() ?? 'No especificada');

    final String imagenUrl = _formatearEnlaceDrive(producto['imagen']);

    return Scaffold(
      appBar: AppBar(
        title: Text(nombre),
        backgroundColor: turquesa,
      ),
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Card(
            color: Colors.white,
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 🖼 Imagen adaptable con el mismo estilo
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: 1, // Mantiene proporción cuadrada
                      child: Container(
                        color: Colors.grey[200],
                        child: imagenUrl.isNotEmpty
                            ? Image.network(
                                imagenUrl,
                                fit: BoxFit.contain, // 🔹 Ajusta sin recortar
                                width: double.infinity,
                              )
                            : const Icon(Icons.image, size: 100),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 📋 Nombre
                  Text(
                    nombre,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // 🔹 Cuadro con info
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(" Precio:", "S/. ${precio.toStringAsFixed(2)}"),
                        _buildInfoRow(" Cantidad:", cantidad),
                        _buildInfoRow(" Disponibilidad:", disponibilidad),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
