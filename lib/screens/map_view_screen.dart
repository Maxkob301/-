import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapViewScreen extends StatelessWidget {
  final double latitude;
  final double longitude;

  const MapViewScreen({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  Widget build(BuildContext context) {
    final point = LatLng(latitude, longitude);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Место на карте'),
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: point,
          initialZoom: 15,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.findback',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: point,
                width: 50,
                height: 50,
                alignment: Alignment.topCenter,
                child: const Icon(
                  Icons.location_pin,
                  size: 42,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}