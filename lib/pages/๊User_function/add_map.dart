import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class GPSandMapPage extends StatefulWidget {
  const GPSandMapPage({super.key});

  @override
  State<GPSandMapPage> createState() => _GPSandMapPageState();
}

class _GPSandMapPageState extends State<GPSandMapPage> {
  GoogleMapController? mapController;
  LatLng? currentPosition;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // ✅ เรียกหลังจาก UI โหลดเสร็จ (ป้องกันค้าง)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCurrentPosition();
    });
  }

  Future<void> _getCurrentPosition() async {
    try {
      setState(() => isLoading = true);

      // ตรวจสอบว่าเปิด Location Service หรือยัง
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'กรุณาเปิด Location Service';
      }

      // ตรวจสอบสิทธิ์เข้าถึงตำแหน่ง
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'ไม่ได้รับอนุญาตให้เข้าถึงตำแหน่ง';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'สิทธิ์ถูกปฏิเสธแบบถาวร กรุณาเปิดสิทธิ์ใน Settings';
      }

      // ✅ ดึงตำแหน่งปัจจุบัน
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        currentPosition = LatLng(position.latitude, position.longitude);
        isLoading = false;
      });

      // ขยับกล้องไปตำแหน่งปัจจุบัน
      mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(currentPosition!, 17),
      );
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C3B66),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C3B66),
        title: const Text(
          "เลือกตำแหน่งบนแผนที่",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _getCurrentPosition, // 🔁 ปุ่มรีเฟรชตำแหน่ง
          ),
        ],
      ),
      body: Stack(
        children: [
          if (currentPosition == null)
            const Center(
              child: Text(
                'กำลังค้นหาตำแหน่ง...',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            )
          else
            GoogleMap(
              onMapCreated: (controller) => mapController = controller,
              initialCameraPosition: CameraPosition(
                target: currentPosition!,
                zoom: 17,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId("current"),
                  position: currentPosition!,
                  draggable: true,
                ),
              },
            ),

          // ปุ่มยืนยันตำแหน่ง
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () {
                        if (currentPosition != null) {
                          Navigator.pop(context, currentPosition);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0C3B66),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Color(0xFF0C3B66))
                    : const Text("ยืนยันตำแหน่ง"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
