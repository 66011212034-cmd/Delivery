import 'package:delivery/pages/%E0%B9%8AUser_function/select_address_page.dart';
import 'package:flutter/material.dart';

//ค้นหา
class SearchCustomerPage extends StatefulWidget {
  const SearchCustomerPage({super.key});

  @override
  State<SearchCustomerPage> createState() => _SearchCustomerPageState();
}

class _SearchCustomerPageState extends State<SearchCustomerPage> {
  final TextEditingController phoneController = TextEditingController();
  List<Map<String, dynamic>> searchResults = [];

  void _search() {
    //ข้อมูลผู้รับสินค้า
    final List<Map<String, dynamic>> dummyData = [
      {
        'name': 'Tumtam Tamtam',
        'phone': '01-111-1111',
        'addresses': [
          {
            'name': 'คณะวิศวกรรมศาสตร์ ม.ใหม่',
            'detail': 'ถ.มหาวิทยาลัย แขวงสวนใหญ่',
            'lat': '10.5965',
            'lng': '2.184',
          },
          {
            'name': 'หมู่บ้าน รอยัลวิลล่า',
            'detail': 'ซอย 16 แขวงบางรัก',
            'lat': '10.474599',
            'lng': '45.2569',
          },
          {
            'name': 'สวนผกา',
            'detail': 'เขตหลักสอง กรุงเทพฯ',
            'lat': '5.264585',
            'lng': '0.2659',
          },
        ],
      },
      {
        'name': 'Mali Kittiya',
        'phone': '02-222-2222',
        'addresses': [
          {
            'name': 'อาคาร A ชั้น 2',
            'detail': 'ถนนลาดพร้าว กรุงเทพฯ',
            'lat': '12.345',
            'lng': '99.888',
          },
        ],
      },
    ];

    final input = phoneController.text.trim();
    final results = dummyData
        .where((data) => data['phone']!.contains(input))
        .toList();

    setState(() {
      searchResults = results;
    });

    if (results.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ไม่พบข้อมูลผู้รับสินค้า')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C3B66),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C3B66),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'ค้นหาข้อมูลผู้รับ',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'เบอร์โทรศัพท์',
                labelStyle: const TextStyle(color: Colors.white),
                filled: true,
                fillColor: const Color(0xFF4E7CBF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.phone, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _search,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 30,
                ),
              ),
              child: const Text(
                'ค้นหา',
                style: TextStyle(
                  color: Color(0xFF0C3B66),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),

            //ค้นหา
            if (searchResults.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: searchResults.length,
                  itemBuilder: (context, index) {
                    final receiver = searchResults[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4E7CBF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            receiver['name'] ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            receiver['phone'] ?? '',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              onPressed: () async {
                                final selected = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SelectAddressPage(
                                      addresses:
                                          receiver['addresses']
                                              as List<Map<String, String>>,
                                    ),
                                  ),
                                );

                                if (selected != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'เลือกที่อยู่: ${selected['name']}',
                                      ),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.yellow,
                              ),
                              child: const Text(
                                'เลือกที่อยู่ผู้รับ',
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
