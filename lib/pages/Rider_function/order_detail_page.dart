import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
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

class OrderDetailPage extends StatefulWidget {
  final String orderId;
  final String riderId;

  const OrderDetailPage({
    super.key,
    required this.orderId,
    required this.riderId,
  });

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  bool isLoading = true;
  bool _hasAccepted = false;
  Map<String, dynamic>? orderData;
  Map<String, dynamic>? parcelData;
  List<LatLng> riderPath = [];

  List<List<LatLng>> routeLines = []; // เก็บเส้นทางตามถนนจริง
  List<LatLng> currentRoute = []; // สำหรับอัปเดต Polyline แบบเรียลไทม์
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initPage(); // โหลดข้อมูลและเส้นทาง
    });
  }

  Future<void> _initPage() async {
    await fetchOrderDetails();

    if (orderData?['riderLat'] != null &&
        orderData?['pickupLat'] != null &&
        orderData?['receiverLat'] != null) {
      final routeFromRider = await getRoutePoints(
        LatLng(orderData!['riderLat'], orderData!['riderLng']),
        LatLng(
          double.parse(orderData!['pickupLat']),
          double.parse(orderData!['pickupLng']),
        ),
      );

      final routeToReceiver = await getRoutePoints(
        LatLng(
          double.parse(orderData!['pickupLat']),
          double.parse(orderData!['pickupLng']),
        ),
        LatLng(
          double.parse(orderData!['receiverLat']),
          double.parse(orderData!['receiverLng']),
        ),
      );

      setState(() {
        routeLines = [routeFromRider, routeToReceiver];
      });
    }

    if (!_hasAccepted) {
      await acceptOrder();
      _hasAccepted = true;
    }

    startRiderLocationTracking();
  }

  Future<void> startRiderLocationTracking() async {
    await Geolocator.requestPermission();

    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5,
          ),
        ).listen((Position position) async {
          await FirebaseFirestore.instance
              .collection("Order")
              .doc(widget.orderId)
              .update({
                "riderLat": position.latitude,
                "riderLng": position.longitude,
              });

          setState(() {
            orderData?['riderLat'] = position.latitude;
            orderData?['riderLng'] = position.longitude;

            // เก็บเส้นทาง Rider
            riderPath.add(LatLng(position.latitude, position.longitude));
          });
        });
  }

  @override
  void dispose() {
    _positionStream?.cancel(); // ❌ หยุดติดตาม GPS
    super.dispose();
  }

  Future<void> acceptOrder() async {
    print("🚀 เริ่มทำงาน acceptOrder()");

    try {
      final position = await _getCurrentPosition();
      print("📍 พิกัดปัจจุบัน: ${position.latitude}, ${position.longitude}");

      await FirebaseFirestore.instance
          .collection("Order")
          .doc(widget.orderId)
          .set({
            "status": "กำลังจัดส่งงาน",
            "riderId": widget.riderId,
            "riderLat": position.latitude,
            "riderLng": position.longitude,
          }, SetOptions(merge: true));

      print("✅ อัปเดต Order สำเร็จ");

      // โหลดข้อมูลใหม่มาแสดง
      await fetchOrderDetails();
    } catch (e) {
      print("❌ เกิดข้อผิดพลาดใน acceptOrder(): $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("อัปเดตออเดอร์ล้มเหลว: $e")));
    }
  }

  Future<Position> _getCurrentPosition() async {
    print("📡 กำลังขอตำแหน่งปัจจุบัน...");
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> fetchOrderDetails() async {
    print("📦 โหลดข้อมูลออเดอร์จาก Firestore...");
    try {
      final orderDoc = await FirebaseFirestore.instance
          .collection("Order")
          .doc(widget.orderId)
          .get();

      if (!orderDoc.exists) {
        print("⚠️ ไม่พบเอกสาร Order");
        setState(() => isLoading = false);
        return;
      }

      final order = orderDoc.data()!;
      print("✅ โหลด Order สำเร็จ: $order");

      final parcelSnap = await FirebaseFirestore.instance
          .collection("Parcel")
          .where("orderId", isEqualTo: widget.orderId)
          .limit(1)
          .get();

      setState(() {
        orderData = order;
        parcelData = parcelSnap.docs.isNotEmpty
            ? parcelSnap.docs.first.data()
            : null;
        isLoading = false;
      });
    } catch (e) {
      print("❌ Error fetching order: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0C3B66),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (orderData == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0C3B66),
        body: Center(
          child: Text(
            "ไม่พบข้อมูลออเดอร์",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0C3B66),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C3B66),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "รายละเอียดงาน",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF4A90E2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "การจัดส่ง",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("รับงานแล้ว ✅")),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                        ),
                        child: const Text("รับแล้ว"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "รหัสออเดอร์: ${widget.orderId}",
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "ผู้รับ: ${orderData!['receiverName'] ?? '-'}",
                          style: const TextStyle(color: Colors.black),
                        ),
                        Text(
                          "ที่อยู่: ${orderData!['receiverAddress'] ?? '-'}",
                          style: const TextStyle(color: Colors.black),
                        ),
                        Text(
                          "ค่าจัดส่ง: ${orderData!['total_cost'] ?? 0} ฿",
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "สถานะ: ${orderData!['status'] ?? '-'}",
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (parcelData != null) ...[
                          const Divider(),
                          Text(
                            "ชื่อพัสดุ: ${parcelData!['name'] ?? '-'}",
                            style: const TextStyle(color: Colors.black),
                          ),
                          Text(
                            "ราคา: ${parcelData!['price'] ?? 0} ฿",
                            style: const TextStyle(color: Colors.black),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF4A90E2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "แผนที่การจัดส่ง",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    margin: const EdgeInsets.all(16),
                    height: 250,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.grey[300],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter:
                              orderData != null &&
                                  orderData!['pickupLat'] != null
                              ? LatLng(
                                  double.parse(orderData!['pickupLat']),
                                  double.parse(orderData!['pickupLng']),
                                )
                              : LatLng(16.246373, 103.251827),
                          initialZoom: 15.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.thunderforest.com/atlas/{z}/{x}/{y}.png?apikey=f40b14c2ac6146e39fb5c55a0fbf124b',
                            userAgentPackageName: 'com.example.delivery',
                          ),

                          MarkerLayer(
                            markers: [
                              // Rider
                              if (orderData?['riderLat'] != null &&
                                  orderData?['riderLng'] != null)
                                Marker(
                                  point: LatLng(
                                    orderData!['riderLat'],
                                    orderData!['riderLng'],
                                  ),
                                  width: 50,
                                  height: 50,
                                  child: const Icon(
                                    Icons.directions_bike,
                                    color: Colors.blue,
                                    size: 40,
                                  ),
                                ),

                              // Pickup
                              if (orderData?['pickupLat'] != null &&
                                  orderData?['pickupLng'] != null)
                                Marker(
                                  point: LatLng(
                                    double.parse(orderData!['pickupLat']),
                                    double.parse(orderData!['pickupLng']),
                                  ),
                                  width: 50,
                                  height: 50,
                                  child: const Icon(
                                    Icons.store,
                                    color: Colors.orange,
                                    size: 40,
                                  ),
                                ),

                              // Receiver
                              if (orderData?['receiverLat'] != null &&
                                  orderData?['receiverLng'] != null)
                                Marker(
                                  point: LatLng(
                                    double.parse(orderData!['receiverLat']),
                                    double.parse(orderData!['receiverLng']),
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
                          ),

                          // เส้นทางจาก Rider → Pickup → Receiver
                          if (orderData?['riderLat'] != null &&
                              orderData?['pickupLat'] != null &&
                              orderData?['receiverLat'] != null)
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
                        ],
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
  }
}
