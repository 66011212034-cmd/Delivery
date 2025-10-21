import 'package:flutter/material.dart';

//เลือกที่อยู่ผู้รับ
class SelectAddressPage extends StatefulWidget {
  final List<dynamic> addresses;

  const SelectAddressPage({super.key, required this.addresses});

  @override
  State<SelectAddressPage> createState() => _SelectAddressPageState();
}

class _SelectAddressPageState extends State<SelectAddressPage> {
  Map<String, dynamic>? selectedAddress;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C3B66),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C3B66),
        title: const Text(
          "เลือกที่อยู่ผู้รับ",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "ข้อมูลที่อยู่ (${widget.addresses.length} รายการ)",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: widget.addresses.length,
                itemBuilder: (context, index) {
                  final address = widget.addresses[index];
                  final isSelected = selectedAddress == address;

                  return GestureDetector(
                    onTap: () => setState(() => selectedAddress = address),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.yellow[600]
                            : const Color(0xFF4E7CBF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  address['name'],
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.black
                                        : Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "พิกัด: ${address['lat']}, ${address['lng']}",
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.black87
                                  : Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: selectedAddress != null
                  ? () => Navigator.pop(context, selectedAddress)
                  : null,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
              child: const Text(
                "ยืนยัน",
                style: TextStyle(color: Color(0xFF0C3B66)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
