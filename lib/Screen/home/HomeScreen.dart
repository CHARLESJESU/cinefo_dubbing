import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import '../../variables.dart';
import '../../Login/loginscreen.dart';
import '../Profile/ProfileScreen.dart';
import 'package:cinefo_dubbing/Login/password/changepasswordscreen.dart';
import 'SqlitelistScreen.dart';

// Responsive helper class
class ResponsiveHelper {
  final BuildContext context;
  late double screenWidth;
  late double screenHeight;
  late double textScaleFactor;

  ResponsiveHelper(this.context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    textScaleFactor = MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.2);
  }

  // Base width for calculations (iPhone 14 Pro width)
  static const double baseWidth = 393.0;
  static const double baseHeight = 852.0;

  // Get responsive width
  double wp(double percentage) => screenWidth * percentage / 100;

  // Get responsive height
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
  bool get isPhone => screenWidth >= 360 && screenWidth < 600;
  bool get isTablet => screenWidth >= 600 && screenWidth < 900;
  bool get isLargeTablet => screenWidth >= 900;
}

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
    final responsive = ResponsiveHelper(context);

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
          endDrawer: _buildDrawer(context, responsive),
          appBar: _buildAppBar(context, responsive),
          body: RefreshIndicator(
            onRefresh: _fetchLoginData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.only(bottom: responsive.hp(12)),
                child: Column(
                  children: [
                    SizedBox(height: responsive.hp(2.5)),
                    _buildProfileCard(responsive),
                    SizedBox(height: responsive.hp(3)),
                    _buildProjectCard(responsive),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Build responsive drawer
  Widget _buildDrawer(BuildContext context, ResponsiveHelper responsive) {
    return Drawer(
      width: responsive.isTablet ? responsive.wp(50) : responsive.wp(75),
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
                  radius: responsive.sw(40),
                  backgroundColor: Colors.white,
                  child: ClipOval(
                    child: Image.asset(
                      'assets/Dubbing.jpeg',
                      width: responsive.sw(80),
                      height: responsive.sw(80),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.movie,
                        color: const Color(0xFF2B5682),
                        size: responsive.iconSize(40),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _buildDrawerItem(
              context,
              responsive,
              icon: Icons.person,
              title: 'View Profile',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
            ),
            _buildDrawerDivider(responsive),
            _buildDrawerItem(
              context,
              responsive,
              icon: Icons.lock,
              title: 'Change Password',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChangepasswordScreen(),
                  ),
                );
              },
            ),
            _buildDrawerDivider(responsive),
            _buildDrawerItem(
              context,
              responsive,
              icon: Icons.logout,
              title: 'Logout',
              onTap: () {
                Navigator.pop(context);
                _showLogoutDialog(context);
              },
            ),
            _buildDrawerDivider(responsive),
            _buildDrawerItem(
              context,
              responsive,
              icon: Icons.sync,
              title: 'vSync',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Sqlitelist()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    ResponsiveHelper responsive, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: responsive.sw(16),
        vertical: responsive.sh(4),
      ),
      leading: Icon(icon, color: Colors.white, size: responsive.iconSize(24)),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontSize: responsive.sp(16),
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildDrawerDivider(ResponsiveHelper responsive) {
    return Divider(
      color: Colors.white.withOpacity(0.3),
      thickness: 1,
      indent: responsive.sw(16),
      endIndent: responsive.sw(16),
    );
  }

  // Build responsive app bar
  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    ResponsiveHelper responsive,
  ) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: responsive.sh(56),
      leading: Padding(
        padding: EdgeInsets.all(responsive.sw(10)),
        child: Image.asset(
          'assets/cinefo-logo.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.movie,
            color: Colors.white,
            size: responsive.iconSize(24),
          ),
        ),
      ),
      actions: [
        Builder(
          builder: (context) => IconButton(
            icon: Icon(
              Icons.menu,
              color: Colors.white,
              size: responsive.iconSize(24),
            ),
            onPressed: () {
              Scaffold.of(context).openEndDrawer();
            },
          ),
        ),
      ],
    );
  }

  // Build responsive profile card
  Widget _buildProfileCard(ResponsiveHelper responsive) {
    final double avatarRadius = responsive.sw(40).clamp(30.0, 55.0);
    final double avatarImageSize = avatarRadius * 2;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: responsive.wp(7.5)),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: responsive.sh(20),
          horizontal: responsive.sw(10),
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF355E8C),
          borderRadius: BorderRadius.circular(responsive.radius(20)),
        ),
        child: Row(
          children: [
            SizedBox(width: responsive.sw(15)),
            CircleAvatar(
              radius: avatarRadius,
              backgroundColor: Colors.white.withOpacity(0.2),
              child:
                  (_profileImage != null &&
                      _profileImage!.isNotEmpty &&
                      _profileImage!.toLowerCase() != 'unknown')
                  ? ClipOval(
                      child: Image.network(
                        _profileImage!,
                        width: avatarImageSize,
                        height: avatarImageSize,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.person,
                          size: responsive.iconSize(40),
                          color: Colors.white,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.person,
                      size: responsive.iconSize(40),
                      color: Colors.white,
                    ),
            ),
            SizedBox(width: responsive.sw(15)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _managerName ?? '',
                    style: TextStyle(
                      fontSize: responsive.sp(18),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: responsive.sh(4)),
                  Text(
                    _designation ?? '',
                    style: TextStyle(
                      fontSize: responsive.sp(14),
                      color: Colors.white70,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: responsive.sh(2)),
                  Text(
                    _mobileNumber ?? '',
                    style: TextStyle(
                      fontSize: responsive.sp(14),
                      color: Colors.white70,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: responsive.sw(10)),
          ],
        ),
      ),
    );
  }

  // Build responsive project card
  Widget _buildProjectCard(ResponsiveHelper responsive) {
    final double cardHeight = responsive.sh(120).clamp(100.0, 160.0);
    final double iconContainerSize = responsive.sw(50).clamp(40.0, 65.0);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: responsive.wp(7.5)),
      child: Container(
        height: cardHeight,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4A6FA5), Color(0xFF2E4B73)],
          ),
          borderRadius: BorderRadius.circular(responsive.radius(15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: responsive.sw(10),
              offset: Offset(0, responsive.sh(5)),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(responsive.sw(20)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _registeredMovie ?? 'No Project Selection',
                      style: TextStyle(
                        fontSize: responsive.sp(16),
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: responsive.sh(5)),
                    Text(
                      _productionHouse ?? 'N/A',
                      style: TextStyle(
                        fontSize: responsive.sp(14),
                        color: Colors.white.withOpacity(0.8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: responsive.sw(10)),
              Container(
                width: iconContainerSize,
                height: iconContainerSize,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: responsive.sw(2),
                  ),
                ),
                child: Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: responsive.iconSize(35),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
