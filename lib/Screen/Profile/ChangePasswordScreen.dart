import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../variables.dart';
import '../../Login/dialogbox.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController reneterpassword = TextEditingController();
  final TextEditingController currentpassword = TextEditingController();
  final TextEditingController newpassword = TextEditingController();
  bool isloading = false;

  Future<void> changepassword() async {
    setState(() {
      isloading = true;
    });

    try {
      final url =
          processSessionRequest; // Using the global variable from variables.dart

      final response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'VMETID':
              'mAgpajsKo9pVRfBicuVsGkzZG986GWPpxfGpbR9A2ysD1WGBMyqj2gL4NTftf7VABJvOG5KZ9iTW4ybk3oYbnO32oL+b08Ba9MW5pRlI6HaDbOb9pU4iH4VxGB79hQS+27ZzZuTOa9a4e8FrO3ASPC4B21zbSa19fJg1elJ/QK/PkA435B0vpMPKmp4vxfy0/tOEuO3yk5OuykSdwjBHoylNcqeZ2YeUaKeO5W9RwdfKDNMA50GTKxK80PrNQ7RlHJHuYH1NuO84hOvinlrITWc/+MPut0ePT14GyygBCVhRfWioIp3Qyxd+QENfFgqc7UwX8Q8MWERGf5uybUU1Pg==',
          'VSID': vsid ?? loginresponsebody?['vsid'] ?? '',
        },
        body: jsonEncode(<String, dynamic>{
          "vuid": vuid ?? loginresult?['vuid'],
          "mobileNumber": loginmobilenumber
              .text, // Using global controller or local? The snippet used loginresult!['mobileNumber']
          "password": currentpassword.text,
          "newpassword": newpassword.text,
        }),
      );

      setState(() {
        isloading = false;
      });

      if (response.statusCode == 200) {
        DialogHelper.showMessage(
          context,
          "Password changed successfully",
          "OK",
        );
        currentpassword.clear();
        newpassword.clear();
        reneterpassword.clear();
        _popScreenAfterDelay();
      } else {
        DialogHelper.showMessage(
          context,
          "Failed to change the password",
          "OK",
        );
      }
    } catch (e) {
      setState(() {
        isloading = false;
      });
      DialogHelper.showMessage(context, "Something went wrong", "OK");
    }
  }

  void _submitData() {
    if (newpassword.text == reneterpassword.text) {
      if (currentpassword.text.isNotEmpty && newpassword.text.isNotEmpty) {
        changepassword();
      } else {
        DialogHelper.showMessage(context, "Please fill in all fields", "OK");
      }
    } else {
      DialogHelper.showMessage(context, "Passwords don't match", "OK");
    }
  }

  void _popScreenAfterDelay() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Change Password',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create New Password',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Your new password must be different from previous used passwords',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Enter Current Password',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                _buildPasswordField(
                  controller: currentpassword,
                  label: 'Current Password',
                ),
                const SizedBox(height: 20),
                const Text(
                  'Enter New Password',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                _buildPasswordField(
                  controller: newpassword,
                  label: 'New Password',
                ),
                const SizedBox(height: 20),
                const Text(
                  'Re-enter Password',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                _buildPasswordField(
                  controller: reneterpassword,
                  label: 'Re-enter Password',
                ),
                const SizedBox(height: 60),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: isloading ? null : _submitData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2B5682),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: isloading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Change Password',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        hintText: label,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF2B5682)),
        ),
      ),
      onEditingComplete: () {
        FocusScope.of(context).unfocus();
      },
    );
  }
}
