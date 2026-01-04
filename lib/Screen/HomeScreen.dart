import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import '../variables.dart';
import '../Login/loginscreen.dart';
import 'Profile/ProfileScreen.dart';
import 'Profile/ChangePasswordScreen.dart';
import 'SqlitelistScreen.dart';

class MyHomeScreen extends StatefulWidget {
  const MyHomeScreen({super.key});

  @override
  State<MyHomeScreen> createState() => _MyHomeScreenState();
}

class _MyHomeScreenState extends State<MyHomeScreen> {
  String? _managerName;
  String? _designation;
  String? _mobileNumber;
  String? _registeredMovie;
  String? _productionHouse;
  String? _profileImage;

  @override
  void initState() {
    super.initState();
    _fetchLoginData();
  }

  Future<void> _fetchLoginData() async {
    try {
      String dbPath = path.join(
        await getDatabasesPath(),
        'production_login.db',
      );
      final db = await openDatabase(dbPath);
      // Fetch login_data
      final List<Map<String, dynamic>> loginMaps = await db.query(
        'login_data',
        orderBy: 'id ASC',
        limit: 1,
      );
      if (loginMaps.isNotEmpty && mounted) {
        setState(() {
          _managerName = loginMaps.first['manager_name']?.toString() ?? '';
          _designation = loginMaps.first['subUnitName']?.toString() ?? '';

          _mobileNumber = loginMaps.first['mobile_number']?.toString() ?? '';
          _registeredMovie =
              loginMaps.first['registered_movie']?.toString() ?? '';
          _productionHouse =
              loginMaps.first['production_house']?.toString() ?? '';
          _profileImage = loginMaps.first['profile_image']?.toString();

          // Update global variables for consistency across app
          managerName = _managerName;
          designation = _designation;
          registeredMovie = _registeredMovie;
          productionHouse = _productionHouse;
          ProfileImage = _profileImage;
        });
      }
      await db.close();
    } catch (e) {
      if (mounted) {
        setState(() {
          _managerName = '';
          _designation = '';
          _mobileNumber = '';
          _registeredMovie = '';
          _productionHouse = '';
          _profileImage = null;
        });
      }
    }
  }

  // Method to perform logout - delete all login data and navigate to login screen
  Future<void> _performLogout() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Row(
              children: const [
                CircularProgressIndicator(color: Color(0xFF2B5682)),
                SizedBox(width: 20),
                Text('Logging out...'),
              ],
            ),
          );
        },
      );

      // Delete all data from login_data table
      String dbPath = path.join(
        await getDatabasesPath(),
        'production_login.db',
      );
      final db = await openDatabase(dbPath);

      // Delete all records from login_data table
      await db.delete('login_data');
      await db.close();

      // Reset global variables
      managerName = null;
      registeredMovie = null;
      productionHouse = null;
      ProfileImage = null;

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Navigate to login screen and remove all previous routes
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const Loginscreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      print('Error during logout: $e');

      // Close loading dialog if it's open
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error during logout. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Method to show logout confirmation dialog
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Logout',
            style: TextStyle(
              color: Color(0xFF2B5682),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _performLogout(); // Call the logout method
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2B5682), Color(0xFF24426B)],
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          endDrawer: Drawer(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF2B5682), Color(0xFF24426B)],
                ),
              ),
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF2B5682), Color(0xFF24426B)],
                      ),
                    ),
                    child: Center(
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        child: ClipOval(
                          child: Image.asset(
                            'assets/tenkrow.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.movie,
                                  color: Color(0xFF2B5682),
                                  size: 40,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // View Profile
                  ListTile(
                    leading: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 24,
                    ),
                    title: const Text(
                      'View Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context); // Close drawer first
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ),
                      );
                    },
                  ),

                  // White separator line
                  Divider(
                    color: Colors.white.withOpacity(0.3),
                    thickness: 1,
                    indent: 16,
                    endIndent: 16,
                  ),

                  // Change Password
                  ListTile(
                    leading: const Icon(
                      Icons.lock,
                      color: Colors.white,
                      size: 24,
                    ),
                    title: const Text(
                      'Change Password',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context); // Close drawer first
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChangePasswordScreen(),
                        ),
                      );
                    },
                  ),

                  // White separator line
                  Divider(
                    color: Colors.white.withOpacity(0.3),
                    thickness: 1,
                    indent: 16,
                    endIndent: 16,
                  ),

                  // Logout
                  ListTile(
                    leading: const Icon(
                      Icons.logout,
                      color: Colors.white,
                      size: 24,
                    ),
                    title: const Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context); // Close drawer first
                      _showLogoutDialog(context);
                    },
                  ),
                  Divider(
                    color: Colors.white.withOpacity(0.3),
                    thickness: 1,
                    indent: 16,
                    endIndent: 16,
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.sync,
                      color: Colors.white,
                      size: 24,
                    ),
                    title: const Text(
                      'vSync',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context); // Close drawer first
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Sqlitelist()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Image.asset(
                'assets/cinefo-logo.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.movie, color: Colors.white),
              ),
            ),
            actions: [
              // IconButton(
              //   icon: const Icon(Icons.notifications),
              //   color: Colors.white,
              //   iconSize: 24,
              //   onPressed: () {
              //     // TODO: Implement navigation to Approvalstatus
              //   },
              // ),
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () {
                    Scaffold.of(context).openEndDrawer();
                  },
                ),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _fetchLoginData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF355E8C),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 20),
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              child:
                                  (_profileImage != null &&
                                      _profileImage!.isNotEmpty &&
                                      _profileImage!.toLowerCase() != 'unknown')
                                  ? ClipOval(
                                      child: Image.network(
                                        _profileImage!,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(
                                                  Icons.person,
                                                  size: 40,
                                                  color: Colors.white,
                                                ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person,
                                      size: 40,
                                      color: Colors.white,
                                    ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _managerName ?? '',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    _designation ?? '',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  Text(
                                    _mobileNumber ?? '',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF4A6FA5), Color(0xFF2E4B73)],
                          ),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _registeredMovie ??
                                          'No Project Selection',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      _productionHouse ?? 'N/A',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: 35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
