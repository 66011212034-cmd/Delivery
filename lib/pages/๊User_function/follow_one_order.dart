import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// เพิ่มฟังก์ชันเรียกเส้นทางจาก OpenRouteService
Future<List<LatLng>> getRoutePoints(LatLng start, LatLng end) async {
  const apiKey =
      "eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6ImVjYzc3MWNkYjJiZDRiZjM4ZmIxNmNlMWI1OTM0MWNjIiwiaCI6Im11cm11cjY0In0="; // 🔑 ใส่ API Key ของคุณ
  final url = Uri.parse(
    "https://api.openrouteservice.org/v2/directions/driving-car?api_key=$apiKey&start=${start.longitude},${start.latitude}&end=${end.longitude},${end.latitude}",
  );

  final response = await http.get(url);
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    final coords = data['features'][0]['geometry']['coordinates'] as List;
    return coords.map((c) => LatLng(c[1], c[0])).toList();
  } else {
    print("Failed to get route: ${response.statusCode}");
    return [];
  }
}

List<List<LatLng>> routeLines = []; // เก็บเส้นทางตามถนนจริง

class FollowOneOrderPage extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic> orderData;

  const FollowOneOrderPage({
    super.key,
    required this.orderId,
    required this.orderData,
  });

  @override
  State<FollowOneOrderPage> createState() => _FollowOneOrderPageState();
}

class _FollowOneOrderPageState extends State<FollowOneOrderPage> {
  List<LatLng> routeLine = [];

  Future<Map<String, dynamic>?> fetchOrderData() async {
    try {
      final orderSnap = await FirebaseFirestore.instance
          .collection('Order')
          .doc(widget.orderId)
          .get();

      if (!orderSnap.exists) return null;

      final order = orderSnap.data()!;

      // ✅ โหลดเส้นทางจริงตามถนน
      if (order['pickupLat'] != null && order['receiverLat'] != null) {
        final line = await getRoutePoints(
          LatLng(
            double.parse(order['pickupLat']),
            double.parse(order['pickupLng']),
          ),
          LatLng(
            double.parse(order['receiverLat']),
            double.parse(order['receiverLng']),
          ),
        );
        routeLine = line;
        routeLines = [routeLine];
      }

      return order;
    } catch (e) {
      print("Error: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C3B66),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C3B66),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "ติดตามสถานะสินค้า",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: fetchOrderData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text(
                "ไม่พบข้อมูลออเดอร์นี้",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final order = snapshot.data!;
          final parcel = order['parcel'] ?? {};

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ✅ ข้อมูลพัสดุ
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF9C4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "ข้อมูลพัสดุ",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text(
                              "ชื่อสินค้า: ",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                parcel['name'] ?? "ไม่ระบุชื่อพัสดุ",
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text(
                              "ราคา: ",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              "${parcel['price'] ?? order['total_cost'] ?? 0} ฿",
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ✅ สถานะ
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        order['status'] ?? "รออัปเดตสถานะ",
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ✅ ข้อมูลผู้รับ
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A90E2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.person, color: Colors.white),
                            SizedBox(width: 6),
                            Text(
                              "ข้อมูลผู้รับ",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "ชื่อผู้รับ: ",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                order['receiverName'] ?? "ไม่พบชื่อผู้รับ",
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "ที่อยู่จัดส่ง: ",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                order['receiverAddress'] ??
                                    "ไม่พบข้อมูลที่อยู่จัดส่ง",
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ✅ แผนที่แสดงตำแหน่งจัดส่ง
                  // ✅ แผนที่ละเอียดเหมือนหน้า All Orders
                  Container(
                    height: 350,
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: LatLng(
                            double.parse(order['pickupLat'] ?? '16.246373'),
                            double.parse(order['pickupLng'] ?? '103.251827'),
                          ),
                          initialZoom: 15.0,
                        ),
                        children: [
                          // ✅ พื้นหลังแผนที่
                          TileLayer(
                            urlTemplate:
                                'https://tile.thunderforest.com/atlas/{z}/{x}/{y}.png?apikey=f40b14c2ac6146e39fb5c55a0fbf124b',
                            userAgentPackageName: 'com.example.delivery',
                          ),

                          // ✅ เส้นเชื่อม pickup → receiver → rider
                          PolylineLayer(
                            polylines: [
                              for (var line in routeLines)
                                Polyline(
                                  points: line,
                                  color: Colors.green,
                                  strokeWidth: 4,
                                ),
                            ],
                          ),

                          // ✅ Marker พร้อม popup แสดงข้อมูล
                          PopupMarkerLayerWidget(
                            options: PopupMarkerLayerOptions(
                              markers: [
                                if (order['riderLat'] != null &&
                                    order['riderLng'] != null)
                                  Marker(
                                    point: LatLng(
                                      double.parse(
                                        order['riderLat'].toString(),
                                      ),
                                      double.parse(
                                        order['riderLng'].toString(),
                                      ),
                                    ),
                                    width: 50,
                                    height: 50,
                                    child: const Icon(
                                      Icons.directions_bike,
                                      color: Colors.blue,
                                      size: 40,
                                    ),
                                  ),
                                if (order['pickupLat'] != null &&
                                    order['pickupLng'] != null)
                                  Marker(
                                    point: LatLng(
                                      double.parse(order['pickupLat']),
                                      double.parse(order['pickupLng']),
                                    ),
                                    width: 50,
                                    height: 50,
                                    child: const Icon(
                                      Icons.store,
                                      color: Colors.orange,
                                      size: 40,
                                    ),
                                  ),
                                if (order['receiverLat'] != null &&
                                    order['receiverLng'] != null)
                                  Marker(
                                    point: LatLng(
                                      double.parse(order['receiverLat']),
                                      double.parse(order['receiverLng']),
                                    ),
                                    width: 50,
                                    height: 50,
                                    child: const Icon(
                                      Icons.location_on,
                                      color: Colors.red,
                                      size: 40,
                                    ),
                                  ),
                              ],
                              popupDisplayOptions: PopupDisplayOptions(
                                builder: (BuildContext context, Marker marker) {
                                  String type = '';

                                  if (order['riderLat'] != null &&
                                      marker.point.latitude ==
                                          double.parse(
                                            order['riderLat'].toString(),
                                          ) &&
                                      marker.point.longitude ==
                                          double.parse(
                                            order['riderLng'].toString(),
                                          )) {
                                    type = 'Rider';
                                  } else if (order['pickupLat'] != null &&
                                      marker.point.latitude ==
                                          double.parse(
                                            order['pickupLat'].toString(),
                                          ) &&
                                      marker.point.longitude ==
                                          double.parse(
                                            order['pickupLng'].toString(),
                                          )) {
                                    type = 'Pickup';
                                  } else if (order['receiverLat'] != null &&
                                      marker.point.latitude ==
                                          double.parse(
                                            order['receiverLat'].toString(),
                                          ) &&
                                      marker.point.longitude ==
                                          double.parse(
                                            order['receiverLng'].toString(),
                                          )) {
                                    type = 'Receiver';
                                  }

                                  return Card(
                                    color: Colors.white,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Text(
                                        'Order: ${widget.orderId}\n$type',

                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  // ✅ รูปภาพพัสดุ
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.image, color: Colors.white),
                            SizedBox(width: 6),
                            Text(
                              "รูปภาพพัสดุ",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child:
                              (order['imagePath'] != null &&
                                  order['imagePath'].toString().isNotEmpty)
                              ? Image.file(
                                  File(order['imagePath']),
                                  fit: BoxFit.cover,
                                  height: 200,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        height: 200,
                                        color: Colors.white12,
                                        alignment: Alignment.center,
                                        child: const Text(
                                          "ไม่สามารถโหลดรูปภาพได้",
                                          style: TextStyle(
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ),
                                )
                              : Container(
                                  height: 200,
                                  color: Colors.white12,
                                  alignment: Alignment.center,
                                  child: const Text(
                                    "ไม่พบรูปภาพ",
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
