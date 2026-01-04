import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _profileImage;
  Map<String, dynamic>? loginData;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
      // Optionally save the local path to SQLite here if needed
    }
  }

  Future<void> _fetchLoginData() async {
    try {
      final dbPath = await getDatabasesPath();
      final db = await openDatabase(path.join(dbPath, 'production_login.db'));
      final List<Map<String, dynamic>> loginMaps = await db.query('login_data');
      if (loginMaps.isNotEmpty) {
        setState(() {
          loginData = loginMaps.first;
        });
      }
      await db.close();
    } catch (e) {
      print('Error fetching login data: $e');
    }
  }

  Widget buildProfileField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 120,
              child: Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchLoginData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFF2B5682,
      ), // Matching the home screen primary color
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Profile Info',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: loginData == null
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.white24,
                          backgroundImage: _profileImage != null
                              ? FileImage(_profileImage!)
                              : (loginData!['profile_image'] != null &&
                                    loginData!['profile_image']
                                        .toString()
                                        .startsWith('http'))
                              ? NetworkImage(loginData!['profile_image'])
                              : const AssetImage('assets/tenkrow.png')
                                    as ImageProvider,
                        ),
                      ),
                      Positioned(
                        right: 5,
                        bottom: 5,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: const CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.edit,
                              size: 18,
                              color: Color(0xFF2B5682),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    loginData?["manager_name"] ?? 'N/A',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    "Dubbing Manager",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Divider(color: Colors.white24, thickness: 1),
                  ),
                  const SizedBox(height: 10),
                  buildProfileField(
                    'Name',
                    loginData?["manager_name"] ?? 'N/A',
                  ),
                  buildProfileField(
                    'Mobile',
                    loginData?["mobile_number"] ?? 'N/A',
                  ),
                  buildProfileField('Email', loginData?["email"] ?? 'N/A'),
                  buildProfileField('Designation', 'Dubbing Manager'),
                  buildProfileField(
                    'Production House',
                    loginData?["production_house"] ?? 'N/A',
                  ),
                  buildProfileField(
                    'Registered Movie',
                    loginData?["registered_movie"] ?? 'N/A',
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}
