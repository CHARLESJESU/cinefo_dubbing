import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

// Responsive helper class
class ResponsiveHelper {
  final BuildContext context;
  late double screenWidth;
  late double screenHeight;

  ResponsiveHelper(this.context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
  }

  // Base width for calculations (iPhone 14 Pro width)
  static const double baseWidth = 393.0;
  static const double baseHeight = 852.0;

  // Get responsive width percentage
  double wp(double percentage) => screenWidth * percentage / 100;

  // Get responsive height percentage
  double hp(double percentage) => screenHeight * percentage / 100;

  // Get scaled width based on design width
  double sw(double size) => size * screenWidth / baseWidth;

  // Get scaled height based on design height
  double sh(double size) => size * screenHeight / baseHeight;

  // Get responsive font size
  double sp(double size) {
    double scaleFactor = screenWidth / baseWidth;
    return (size * scaleFactor).clamp(size * 0.8, size * 1.3);
  }

  // Get responsive radius
  double radius(double size) => sw(size);

  // Get responsive icon size
  double iconSize(double size) => sw(size).clamp(size * 0.8, size * 1.5);

  // Check device type
  bool get isSmallPhone => screenWidth < 360;
  bool get isTablet => screenWidth >= 600;
}

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

  Widget buildProfileField(
    String label,
    String value,
    ResponsiveHelper responsive,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.sw(16),
        vertical: responsive.sh(8),
      ),
      child: Container(
        padding: EdgeInsets.all(responsive.sw(12)),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(responsive.radius(10)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: responsive.sw(110),
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: responsive.sp(14),
                ),
              ),
            ),
            SizedBox(width: responsive.sw(10)),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: responsive.sp(15),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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
    final responsive = ResponsiveHelper(context);
    final double avatarRadius = responsive.sw(55).clamp(45.0, 75.0);
    final double editButtonRadius = responsive.sw(18).clamp(14.0, 24.0);

    return Scaffold(
      backgroundColor: const Color(0xFF2B5682),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: responsive.sh(56),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: responsive.iconSize(22),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Profile Info',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: responsive.sp(18),
          ),
        ),
      ),
      body: loginData == null
          ? Center(
              child: SizedBox(
                width: responsive.sw(40),
                height: responsive.sw(40),
                child: const CircularProgressIndicator(color: Colors.white),
              ),
            )
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  SizedBox(height: responsive.hp(2.5)),
                  // Profile Image with Edit Button
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: responsive.sw(3),
                          ),
                        ),
                        child: CircleAvatar(
                          radius: avatarRadius,
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
                        right: responsive.sw(5),
                        bottom: responsive.sw(5),
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: CircleAvatar(
                            radius: editButtonRadius,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.edit,
                              size: responsive.iconSize(18),
                              color: const Color(0xFF2B5682),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: responsive.hp(1.8)),
                  // User Name
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: responsive.sw(20),
                    ),
                    child: Text(
                      loginData?["manager_name"] ?? 'N/A',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: responsive.sp(22),
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(height: responsive.sh(4)),
                  // Designation
                  Text(
                    "Dubbing Manager",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: responsive.sp(14),
                    ),
                  ),
                  SizedBox(height: responsive.hp(2.5)),
                  // Divider
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: responsive.sw(16),
                    ),
                    child: const Divider(color: Colors.white24, thickness: 1),
                  ),
                  SizedBox(height: responsive.hp(1.2)),
                  // Profile Fields
                  buildProfileField(
                    'Name',
                    loginData?["manager_name"] ?? 'N/A',
                    responsive,
                  ),
                  buildProfileField(
                    'Mobile',
                    loginData?["mobile_number"] ?? 'N/A',
                    responsive,
                  ),
                  buildProfileField(
                    'Email',
                    loginData?["email"] ?? 'N/A',
                    responsive,
                  ),
                  buildProfileField(
                    'Designation',
                    'Dubbing Manager',
                    responsive,
                  ),
                  buildProfileField(
                    'Production House',
                    loginData?["production_house"] ?? 'N/A',
                    responsive,
                  ),
                  buildProfileField(
                    'Registered Movie',
                    loginData?["registered_movie"] ?? 'N/A',
                    responsive,
                  ),
                  SizedBox(height: responsive.hp(4)),
                ],
              ),
            ),
    );
  }
}
