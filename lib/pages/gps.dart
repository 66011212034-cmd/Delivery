import 'dart:developer' show log;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class GPSandMapPage extends StatefulWidget {
  const GPSandMapPage({super.key});

  @override
  State<GPSandMapPage> createState() => _GPSandMapPageState();
}

class _GPSandMapPageState extends State<GPSandMapPage> {
  final MapController mapController = MapController();
  LatLng? selectedPoint;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GPS and Map')),
      body: Column(
        children: [
          // FilledButton(
          //   onPressed: () async {
          //     var position = await _determinePosition();
          //     log('${position.latitude} ${position.longitude}');
          //     setState(() {
          //       selectedPoint = LatLng(position.latitude, position.longitude);
          //     });
          //     mapController.move(
          //       LatLng(position.latitude, position.longitude),
          //       16,
          //     );
          //   },
          //   child: const Text('Get Location'),
          // ),
          Expanded(
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: LatLng(16.246373, 103.251827),
                initialZoom: 15.2,
                onTap: (tapPosition, point) {
                  log(point.toString());
                  setState(() {
                    selectedPoint = point;
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.thunderforest.com/atlas/{z}/{x}/{y}.png?apikey=f40b14c2ac6146e39fb5c55a0fbf124b',
                  userAgentPackageName: 'com.example.project_lottoy',
                ),
                MarkerLayer(
                  markers: [
                    if (selectedPoint != null)
                      Marker(
                        point: selectedPoint!,
                        width: 50,
                        height: 50,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: () {
              if (selectedPoint != null) {
                Navigator.pop(
                  context,
                  selectedPoint,
                ); 
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('กรุณาเลือกตำแหน่งบนแผนที่')),
                );
              }
            },
            child: const Text("ยืนยันตำแหน่ง"),
          ),
        ],
      ),
    );
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    return await Geolocator.getCurrentPosition();
  }
}
