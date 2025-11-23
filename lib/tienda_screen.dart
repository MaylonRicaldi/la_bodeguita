import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:animate_do/animate_do.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';

class TiendaScreen extends StatefulWidget {
  const TiendaScreen({super.key});

  @override
  State<TiendaScreen> createState() => _TiendaScreenState();
}

class _TiendaScreenState extends State<TiendaScreen> {
  LatLng? ubicacionUsuario;
  LatLng? ubicacionTienda;
  GoogleMapController? mapController;
  Set<Polyline> polylines = {};
  BitmapDescriptor? iconoTienda;
  BitmapDescriptor? iconoPersona;
  final String apiKey = "AIzaSyBIZrptkE0IGakPhzMzMpq4PaW_gw_D1vk"; // key del profesor

  @override
  void initState() {
    super.initState();
    cargarIconosPersonalizados();
    obtenerUbicacionUsuario();
    obtenerUbicacionTienda();
  }


  Future<void> cargarIconosPersonalizados() async {
    try {
      // Ícono de la tienda
      final ByteData tiendaData = await rootBundle.load('assets/bodeguita_icon.png');
      final Uint8List tiendaBytes = tiendaData.buffer.asUint8List();
      final ui.Codec tiendaCodec = await ui.instantiateImageCodec(
        tiendaBytes,
        targetWidth: 120,
        targetHeight: 120,
      );
      final ui.FrameInfo tiendaFrame = await tiendaCodec.getNextFrame();
      final ByteData? tiendaResized = await tiendaFrame.image.toByteData(format: ui.ImageByteFormat.png);
      final BitmapDescriptor iconTienda = BitmapDescriptor.fromBytes(tiendaResized!.buffer.asUint8List());

      // Ícono de la persona
      final ByteData personaData = await rootBundle.load('assets/persona_icon.png');
      final Uint8List personaBytes = personaData.buffer.asUint8List();
      final ui.Codec personaCodec = await ui.instantiateImageCodec(
        personaBytes,
        targetWidth: 120,
        targetHeight: 120,
      );
      final ui.FrameInfo personaFrame = await personaCodec.getNextFrame();
      final ByteData? personaResized = await personaFrame.image.toByteData(format: ui.ImageByteFormat.png);
      final BitmapDescriptor iconPersona = BitmapDescriptor.fromBytes(personaResized!.buffer.asUint8List());

      setState(() {
        iconoTienda = iconTienda;
        iconoPersona = iconPersona;
      });
    } catch (e) {
      debugPrint("❌ Error al cargar íconos personalizados: $e");
    }
  }

  Future<void> obtenerUbicacionUsuario() async {
    bool servicioHabilitado = await Geolocator.isLocationServiceEnabled();
    if (!servicioHabilitado) return;

    LocationPermission permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied) return;
    }
    if (permiso == LocationPermission.deniedForever) return;

    Position posicion = await Geolocator.getCurrentPosition();

    setState(() {
      ubicacionUsuario = LatLng(posicion.latitude, posicion.longitude);
    });

    if (ubicacionTienda != null) {
      obtenerRuta();
      moverCamara();
    }
  }

  Future<void> obtenerUbicacionTienda() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('Tienda')
        .doc('principal')
        .get();

    final data = snapshot.data();

    if (data != null && data['ubicacion'] != null) {
      final geo = data['ubicacion'] as GeoPoint;
      setState(() {
        ubicacionTienda = LatLng(geo.latitude, geo.longitude);
      });

      if (ubicacionUsuario != null) {
        obtenerRuta();
        moverCamara();
      }
    }
  }


  Future<void> obtenerRuta() async {
    if (ubicacionUsuario == null || ubicacionTienda == null) return;

    final origen =
        "${ubicacionUsuario!.latitude},${ubicacionUsuario!.longitude}";
    final destino =
        "${ubicacionTienda!.latitude},${ubicacionTienda!.longitude}";
    final url = Uri.parse(
        "https://maps.googleapis.com/maps/api/directions/json?origin=$origen&destination=$destino&key=$apiKey&mode=driving");

    final respuesta = await http.get(url);
    if (respuesta.statusCode == 200) {
      final data = json.decode(respuesta.body);
      if (data["routes"].isNotEmpty) {
        final puntos = data["routes"][0]["overview_polyline"]["points"];
        final ruta = decodePolyline(puntos);
        setState(() {
          polylines = {
            Polyline(
              polylineId: const PolylineId("ruta"),
              color: Colors.teal,
              width: 5,
              points: ruta,
            )
          };
        });
      }
    }
  }


  List<LatLng> decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;
    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;
      polyline.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return polyline;
  }

  void moverCamara() async {
  if (mapController == null || ubicacionUsuario == null || ubicacionTienda == null) return;

  try {

    final bounds = LatLngBounds(
      southwest: LatLng(
        (ubicacionUsuario!.latitude < ubicacionTienda!.latitude)
            ? ubicacionUsuario!.latitude
            : ubicacionTienda!.latitude,
        (ubicacionUsuario!.longitude < ubicacionTienda!.longitude)
            ? ubicacionUsuario!.longitude
            : ubicacionTienda!.longitude,
      ),
      northeast: LatLng(
        (ubicacionUsuario!.latitude > ubicacionTienda!.latitude)
            ? ubicacionUsuario!.latitude
            : ubicacionTienda!.latitude,
        (ubicacionUsuario!.longitude > ubicacionTienda!.longitude)
            ? ubicacionUsuario!.longitude
            : ubicacionTienda!.longitude,
      ),
    );

    await Future.delayed(const Duration(milliseconds: 600));

    await mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 120.0), // padding visual
    );
  } catch (e) {
    debugPrint("⚠️ Error al mover la cámara: $e");
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      backgroundColor: Colors.teal,
      title: Row(
        children: [
          Text(
            "Cómo llegar a la tienda",
            style: TextStyle(
              fontSize: 22,                 // estilo Catálogo
              fontWeight: FontWeight.bold,
              color: Colors.white,         // color blanco
            ),
          ),
        ],
      ),
    ),

      body: (ubicacionUsuario == null || ubicacionTienda == null)
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Pulse(
                        infinite: true,
                        duration: const Duration(seconds: 2),
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.teal.withOpacity(0.15),
                          ),
                        ),
                      ),
                      Pulse(
                        infinite: true,
                        duration: const Duration(seconds: 3),
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.teal.withOpacity(0.25),
                          ),
                        ),
                      ),
                      BounceInDown(
                        child: Icon(
                          Icons.location_on,
                          color: Colors.teal,
                          size: 85,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  FadeInUp(
                    duration: const Duration(milliseconds: 800),
                    child: Text(
                      "Localizando tu ubicación...",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),
            )
          : FadeIn(
              duration: const Duration(milliseconds: 800),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: ubicacionUsuario!,
                  zoom: 13,
                ),
                markers: {

                  Marker(
                    markerId: const MarkerId('usuario'),
                    position: ubicacionUsuario!,
                    infoWindow: const InfoWindow(title: 'Tú'),
                    icon: iconoPersona ??
                        BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueAzure),
                  ),

                  Marker(
                    markerId: const MarkerId('tienda'),
                    position: ubicacionTienda!,
                    infoWindow:
                        const InfoWindow(title: 'La Bodeguita S.A.C.'),
                    icon: iconoTienda ??
                        BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueRed),
                  ),
                },
                polylines: polylines,
                onMapCreated: (controller) => mapController = controller,
                myLocationEnabled: false,
              ),
            ),
    );
  }
}
