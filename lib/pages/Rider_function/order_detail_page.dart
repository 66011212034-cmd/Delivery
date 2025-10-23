import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class OrderDetailPage extends StatefulWidget {
  final String orderId;
  final String riderId; // ✅ เพิ่ม

  const OrderDetailPage({
    super.key,
    required this.orderId,
    required this.riderId,
  });

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  Map<String, dynamic>? orderData;
  Map<String, dynamic>? parcelData;
  bool isLoading = true;
  bool orderAccepted = false; // เช็คว่ารับงานแล้ว

  @override
  void initState() {
    super.initState();
    fetchOrderDetails();

    // ✅ เรียก acceptOrder อัตโนมัติหลัง build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      acceptOrder();
    });
  }

  /// โหลดข้อมูล Order และ Parcel
  Future<void> fetchOrderDetails() async {
    try {
      final orderDoc = await FirebaseFirestore.instance
          .collection("Order")
          .doc(widget.orderId)
          .get();

      if (orderDoc.exists) {
        final order = orderDoc.data()!;
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
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("❌ Error fetching order: $e");
      setState(() => isLoading = false);
    }
  }

  /// รับงาน → อัปเดต Order + Rider + บันทึกพิกัด
  Future<void> acceptOrder() async {
    if (orderAccepted) return; // ป้องกันเรียกซ้ำ
    orderAccepted = true;

    try {
      // 1️⃣ ขอสิทธิ์ตำแหน่ง
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("กรุณาอนุญาตการเข้าถึงตำแหน่งก่อน")),
        );
        return;
      }

      // 2️⃣ ดึงตำแหน่งปัจจุบัน
      final position = await Geolocator.getCurrentPosition();
      print("📍 Position: ${position.latitude}, ${position.longitude}");
      print("🆔 Order ID: ${widget.orderId}");
      print("🛵 Rider ID: ${widget.riderId}");

      // 3️⃣ ตรวจสอบว่ามี document จริงไหม
      final docSnap = await FirebaseFirestore.instance
          .collection("Order")
          .doc(widget.orderId)
          .get();
      print("📌 Document exists? ${docSnap.exists}");

      if (!docSnap.exists) {
        print("❌ ไม่พบ Order ใน Firestore");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("ไม่พบข้อมูลออเดอร์ในระบบ")),
        );
        return;
      }

      // 4️⃣ อัปเดต Order
      try {
        await FirebaseFirestore.instance
            .collection("Order")
            .doc(widget.orderId)
            .set({
              "status": "กำลังจัดส่งงาน",
              "riderId": widget.riderId,
              "riderLat": position.latitude,
              "riderLng": position.longitude,
            }, SetOptions(merge: true));
        print("✅ Order อัปเดตเรียบร้อย");
        setState(() {
          orderData?['status'] = "กำลังจัดส่งงาน";
        });
      } catch (e) {
        print("❌ Error อัปเดต Order: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("เกิดข้อผิดพลาดในการอัปเดต Order")),
        );
        return;
      }

      // 5️⃣ อัปเดต Rider
      try {
        await FirebaseFirestore.instance
            .collection("Rider")
            .doc(widget.riderId)
            .update({
              "status": "กำลังจัดส่งงาน",
              "currentLat": position.latitude,
              "currentLng": position.longitude,
            });
        print("✅ Rider อัปเดตเรียบร้อย");
      } catch (e) {
        print("❌ Error อัปเดต Rider: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("เกิดข้อผิดพลาดในการอัปเดต Rider")),
        );
        return;
      }

      // 6️⃣ แจ้งผู้ใช้
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("รับงานเรียบร้อยแล้ว ✅")));
    } catch (e) {
      print("❌ Error ใน acceptOrder: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("เกิดข้อผิดพลาด")));
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
            // 🔹 กล่องข้อมูลออเดอร์
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF4A90E2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // หัวข้อ + ปุ่มรับแล้ว
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

            // 🔹 กล่องแผนที่
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
                          initialCenter: LatLng(16.246373, 103.251827),
                          initialZoom: 15.2,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.thunderforest.com/atlas/{z}/{x}/{y}.png?apikey=f40b14c2ac6146e39fb5c55a0fbf124b',
                            userAgentPackageName: 'com.example.delivery',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(16.246373, 103.251827),
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
