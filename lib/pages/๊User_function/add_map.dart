import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class GPSandMapPage extends StatefulWidget {
  const GPSandMapPage({super.key});

  @override
  State<GPSandMapPage> createState() => _GPSandMapPageState();
}

class _GPSandMapPageState extends State<GPSandMapPage> {
  String locationMessage = "ตำแหน่งยังไม่ถูกระบุ";

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('กรุณาเปิด Location Service');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('ไม่ได้รับอนุญาตให้เข้าถึงตำแหน่ง');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('สิทธิ์ถูกปฏิเสธถาวร');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await _determinePosition();
      setState(() {
        locationMessage =
            "ละติจูด: ${position.latitude}, ลองจิจูด: ${position.longitude}";
      });
      log('ตำแหน่งปัจจุบัน: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      setState(() {
        locationMessage = "เกิดข้อผิดพลาด: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C3B66),
      appBar: AppBar(
        title: const Text('GPS and Map'),
        backgroundColor: const Color(0xFF0C3B66),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, color: Colors.white, size: 80),
              const SizedBox(height: 20),
              Text(
                locationMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _getCurrentLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0C3B66),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 60,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('ดึงตำแหน่งปัจจุบัน'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
