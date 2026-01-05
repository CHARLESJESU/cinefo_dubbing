import 'package:flutter/material.dart';

import '../../service/update_service.dart';
import '../Login/loginscreen.dart';
import '../Login/loginsqlitecode.dart';
import '../Route/RouteScreenfordubbingincharge.dart';
import '../variables.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeSplashScreen();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      UpdateService.checkAndPerformUpdate(context);
    });
  }

  Future<void> _initializeSplashScreen() async {
    // Wait for 1 second to display splash screen
    await Future.delayed(Duration(seconds: 1));

    try {
      // Get active login data using LoginSQLiteHelper
      final loginData = await LoginSQLiteHelper.getActiveLoginData();

      if (loginData != null) {
        print('🔍 DEBUG: Login data found');
        print('🔍 DEBUG: VSID: ${loginData['vsid']}');
        print('🔍 DEBUG: Driver: ${loginData['driver']}');
        print('🔍 DEBUG: Manager: ${loginData['manager_name']}');

        // Load stored data into global variables
        _loadStoredDataIntoVariables(loginData);

        // Check vsid and navigate accordingly
        if (loginData['vsid'] == null) {
          // Navigate to login screen if vsid is null
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Loginscreen()),
            );
          }
        } else {
          // vsid exists - decide route based on driver flag
          final dynamic driverFlag = loginData['driver'];
          final dynamic agentFlag = loginData['isAgentt'];

          bool isDriver = _parseBooleanFlag(driverFlag, 'Driver');
          bool isAgent = _parseBooleanFlag(agentFlag, 'Agent');

          print('🔍 DEBUG: Final isDriver=$isDriver, isAgent=$isAgent');

          if (mounted) { 
            if (loginData!=null) {
              print('🔍 DEBUG: Navigating to RoutescreenforIncharge');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const RoutescreenforDubbingIncharge(),
                ),
              );
            }
          }
        }
      } else {
        // No login data found, navigate to login screen
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Loginscreen()),
          );
        }
      }
    } catch (e) {
      print('Error during splash initialization: $e');
      // On error, navigate to login screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Loginscreen()),
        );
      }
    }
  }

  // Helper method to parse boolean flags from various types
  bool _parseBooleanFlag(dynamic flag, String flagName) {
    if (flag is int && flag == 1) {
      print('🔍 DEBUG: $flagName flag matched as int 1');
      return true;
    }
    if (flag is bool && flag == true) {
      print('🔍 DEBUG: $flagName flag matched as bool true');
      return true;
    }
    if (flag is String && (flag == '1' || flag.toLowerCase() == 'true')) {
      print('🔍 DEBUG: $flagName flag matched as string');
      return true;
    }
    return false;
  }

  // Load stored data into global variables
  void _loadStoredDataIntoVariables(Map<String, dynamic> loginData) {
    managerName = loginData['manager_name'];
    registeredMovie = loginData['registered_movie'];
    projectId = loginData['project_id'];
    productionTypeId = loginData['production_type_id'] ?? 0;
    productionHouse = loginData['production_house'] ?? ' ';
    vmid = loginData['vmid'] ?? 0;

    // Convert driver field from int to bool
    final driverValue = loginData['driver'];
    driver = _parseBooleanFlag(driverValue, 'Driver (in load)');

    // Set mobile number and password in controllers
    loginmobilenumber.text = loginData['mobile_number'] ?? '';
    loginpassword.text = loginData['password'] ?? '';

    print('Loaded stored data: Manager=$managerName, Movie=$registeredMovie');
    print(
      '🔍 DEBUG: Converted driver value $driverValue (${driverValue.runtimeType}) to bool: $driver',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF2B5682),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Logo
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(cinefo__logo, fit: BoxFit.cover),
                      ),
                    ),

                    SizedBox(height: 30),

                    // App Title
                    Text(
                      'Dubbing App',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),

                    SizedBox(height: 50),
                  ],
                ),
              ),
            ),

            // Version info
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                'v.4.0.2',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
