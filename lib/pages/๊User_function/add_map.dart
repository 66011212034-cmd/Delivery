import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
//หน้าเพิ่มแผนที่
class AddMap extends StatefulWidget {
  const AddMap({super.key});

  @override
  State<AddMap> createState() => _WorkingOrderPageState();
}

class _WorkingOrderPageState extends State<AddMap> {
  // พิกัด(ดึงจากFirebase)
  final LatLng deliveryLocation = const LatLng(13.7563, 100.5018);

  GoogleMapController? mapController;

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C3B66),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C3B66),
        title: const Text(
          'งานที่กำลังดำเนินการ',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),

      body: Column(
        children: [
          Expanded(
            //แผนที่
            child: Container(
              margin: const EdgeInsets.all(16),
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.grey[300],
              ),
              child: const Center(
                child: Icon(Icons.map, color: Colors.grey, size: 80),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ยืนยันตำแหน่งเรียบร้อย')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0C3B66),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 80,
                  vertical: 14,
                ),
              ),
              child: const Text('ยืนยันตำแหน่ง'),
            ),
          ),
        ],
      ),
    );
  }
}
