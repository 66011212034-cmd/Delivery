import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivery/pages/Rider_Profile.dart';
import 'package:delivery/pages/User_Proflie.dart';
import 'package:delivery/pages/page_login.dart';
import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  final String role;
  const RegisterScreen({super.key, required this.role});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController licenseController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C3B66),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(25),
            margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 40),
            decoration: BoxDecoration(
              color: const Color(0xFF4A90E2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  widget.role == "user"
                      ? "สมัครสมาชิก (ผู้ใช้ทั่วไป)"
                      : "สมัครสมาชิก (ไรเดอร์)",
                  style: const TextStyle(
                    color: Colors.yellow,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 25),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "ข้อมูลส่วนตัว",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecoration("เบอร์โทร"),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: firstNameController,
                        decoration: _inputDecoration("ชื่อ"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: lastNameController,
                        decoration: _inputDecoration("นามสกุล"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: _inputDecoration("รหัสผ่าน"),
                ),
                const SizedBox(height: 15),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0C3B66),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    icon: const Icon(Icons.image, color: Colors.white),
                    label: const Text(
                      "เลือกโปรไฟล์",
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () {
                      // TODO: เลือกรูปภาพ
                    },
                  ),
                ),
                const SizedBox(height: 25),

                if (widget.role == "user") ...[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "ข้อมูลที่อยู่",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0C3B66),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      icon: const Icon(Icons.location_on, color: Colors.white),
                      label: const Text(
                        "ปักหมุดที่อยู่บนแผนที่",
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () {
                        // TODO: ไปหน้าเลือกที่อยู่บนแผนที่
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: addressController,
                    decoration: _inputDecoration("ที่อยู่"),
                  ),
                  const SizedBox(height: 20),
                ],

                if (widget.role == "rider") ...[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "ข้อมูลเพิ่มเติมสำหรับไรเดอร์",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0C3B66),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      icon: const Icon(Icons.pedal_bike, color: Colors.white),

                      label: const Text(
                        "รูปยานพาหนะ",
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () {
                        // TODO: เลือกรูปภาพ
                      },
                    ),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: licenseController,
                    decoration: _inputDecoration("ทะเบียนรถ"),
                  ),
                  const SizedBox(height: 12),
                ],

                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0C3B66),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    onPressed: () async {
                      await Register(widget.role);

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                      // if (widget.role == "user") {
                      //   Navigator.pushReplacement(
                      //     context,
                      //     MaterialPageRoute(
                      //       builder: (context) => const UserProflie(),
                      //     ),
                      //   );
                      // } else if (widget.role == "rider") {
                      //   Navigator.pushReplacement(
                      //     context,
                      //     MaterialPageRoute(
                      //       builder: (context) => const RiderProfile(),
                      //     ),
                      //   );
                      // }
                    },
                    child: const Text(
                      "สมัครสมาชิก",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "มีบัญชีผู้ใช้อยู่แล้ว ? ",
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        "เข้าสู่ระบบ",
                        style: TextStyle(
                          color: Color(0xFFFF9800),
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  Future<void> Register(String role) async {
    var db = FirebaseFirestore.instance;

    try {
      if (role == "user") {
        await db.collection("User").doc().set({
          "phone": phoneController.text,
          "firstName": firstNameController.text,
          "lastName": lastNameController.text,
          "password": passwordController.text,
          "address": addressController.text,
          "role": role,
        });
      } else if (role == "rider") {
        await db.collection("Rider").doc().set({
          "phone": phoneController.text,
          "firstName": firstNameController.text,
          "lastName": lastNameController.text,
          "password": passwordController.text,
          "license": licenseController.text,
          "role": role,
        });
      }
      print("Register successful!");
    } catch (e) {
      print("Failed to register: $e");
    }
  }
}
