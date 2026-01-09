import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'password/forgotpassword.dart';

import '../Route/RouteScreenfordubbingincharge.dart';
import '../variables.dart';
import 'loginsqlitecode.dart';
import 'dialogbox.dart';
import 'logindataapiservice.dart';
import '../Screen/home/ProjectListScreen.dart';
import '../common/models/project_model.dart';

class Loginscreen extends StatefulWidget {
  const Loginscreen({super.key});

  @override
  State<Loginscreen> createState() => _LoginscreenState();
}

class _LoginscreenState extends State<Loginscreen> {
  Future<bool> isNfcSupported() async {
    try {
      final availability = await NfcManager.instance.checkAvailability();

      return availability.toString() == 'NfcAvailability.available';
    } catch (e) {
      print('Error checking NFC availability: $e');
      return false;
    }
  }

  bool _isLoading = false;
  bool _obscureText = true;
  String? managerName;
  String? ProfileImage;
  int? vmid;

  Future<void> baseurl() async {
    try {
      final apiResponse = await LoginApiService.fetchBaseUrl(dancebaseurl);

      if (apiResponse['success'] == true) {
        final responseBody = json.decode(apiResponse['body']);
        if (responseBody != null && responseBody['result'] != null) {
          setState(() {
            baseurlresponsebody = responseBody;
            baseurlresult = responseBody['result'];
          });
        } else {
          print('Invalid base URL response structure');
        }
      } else {
        print('Failed to get base URL: ${apiResponse['statusCode']}');
      }
    } catch (e) {
      print('Error in baseurl(): $e');
    }
  }

  Future<void> loginr() async {
    print("loginr() called📊📊📊📊📊📊📊📊📊📊📊📊📊📊📊📊");
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if baseurlresult is available
      if (baseurlresult == null) {
        setState(() {
          _isLoading = false;
        });
        DialogHelper.showMessage(
          context,
          "Base URL not loaded. Please try again.",
          "ok",
        );
        return;
      }

      // Call login API using LoginApiService
      final apiResponse = await LoginApiService.loginUser(
        mobileNumber: loginmobilenumber.text,
        password: loginpassword.text,
        vpid: baseurlresult?['vpid']?.toString() ?? '',
        vptemplateId: baseurlresult?['vptemplteID']?.toString() ?? '',
        baseUrl: dancebaseurl,
      );

      print(
        "Login HTTP status:📊📊📊📊📊📊📊📊📊📊📊📊📊📊📊hvjhjvkjhgvhjgjmnvbkjgjbvn📊 ${apiResponse['statusCode']}",
      );

      setState(() {
        _isLoading = false;
      });

      if (apiResponse['success'] == true) {
        try {
          final responseBody = json.decode(apiResponse['body']);
          print("📊 Decoded JSON response:");
          print("📊 Response keys: ${responseBody.keys.toList()}");

          if (responseBody['responseData'] != null) {
            print(
              "📊 ResponseData keys: ${responseBody['responseData'].keys.toList()}",
            );
            print("📊 ResponseData content: ${responseBody['responseData']}");

            // Check if profileImage exists in responseData
            if (responseBody['responseData']['profileImage'] != null) {
              print(
                "📸 ProfileImage found in responseData: ${responseBody['responseData']['profileImage']}",
              );
            } else {
              print("⚠️ ProfileImage NOT found in responseData");
            }
          }

          if (responseBody['vsid'] != null) {
            print("📊 VSID: ${responseBody['vsid']}");
          }

          if (responseBody != null && responseBody['responseData'] != null) {
            setState(() {
              loginresponsebody = responseBody;
              loginresult = responseBody['responseData'];

              // Update global variables from login response
              if (responseBody['responseData'] is Map) {
                final responseData = responseBody['responseData'];
                projectId = responseData['projectId'] ?? '';
                managerName = responseData['managerName'] ?? '';
                registeredMovie = responseData['projectName'] ?? '';
                vmid = responseData['vmid'] ?? 0;
                productionTypeId = responseData['productionTypeId'] ?? 0;
                productionHouse = responseData['productionHouse'] ?? '';

                print('📊 Updated global variables from login response');
              }

              // Extract ProfileImage from login response
              String? loginProfileImage;
              if (responseBody['responseData'] is Map &&
                  responseBody['responseData']['profileImage'] != null) {
                loginProfileImage =
                    responseBody['responseData']['profileImage'];
              } else if (responseBody['responseData'] is List &&
                  (responseBody['responseData'] as List).isNotEmpty) {
                final firstItem = (responseBody['responseData'] as List)[0];
                if (firstItem is Map && firstItem['profileImage'] != null) {
                  loginProfileImage = firstItem['profileImage'];
                }
              } else if (responseBody['profileImage'] != null) {
                loginProfileImage = responseBody['profileImage'];
              }

              if (loginProfileImage != null &&
                  loginProfileImage.isNotEmpty &&
                  loginProfileImage != 'Unknown') {
                ProfileImage = loginProfileImage;
                print('📸 Updated ProfileImage: $ProfileImage');
              } else {
                print('⚠️ No valid ProfileImage found in login response');
              }
            });

            // Save login data
            if (mounted) {
                // Save login data
                try {
                  print(
                    '🔄 Saving login data to SQLite...',
                  );
                  await LoginSQLiteHelper.saveLoginData(
                    loginresponsebody:
                        loginresponsebody as Map<String, dynamic>?,
                    loginresult: loginresult,
                    mobileNumber: loginmobilenumber.text,
                    password: loginpassword.text,
                    profileImage: ProfileImage,
                  );
                } catch (e) {
                  print(
                    '❌ Error while saving login data: $e',
                  );
                }
                // Make additional HTTP request for drivers
                try {
                  print(
                    '� Checking if user is Incharge or Not (unitid == 5)...',
                  );
  print("Hi appa");
                  // Call InchargeOrNot API after successful login
                  final inchargeApiResponse =
                      await LoginApiService.fetchDriverSession(
                        vmId: loginresponsebody?['responseData']?['vmid'] ?? 0,
                        vsid: loginresponsebody?['vsid']?.toString() ?? "",
                      );

                  vsid = loginresponsebody?['vsid']?.toString() ?? "";
                  print(
                    '� InchargeOrNot API Response Status: ${inchargeApiResponse['statusCode']}',
                  );
                  print(
                    '� InchargeOrNot API Response Body: ${inchargeApiResponse['body']}',
                  );

                  if (inchargeApiResponse['success'] == true) {
                    try {
                      final inchargeResponseBody = json.decode(
                        inchargeApiResponse['body'],
                      );
                      print(
                        '� InchargeOrNot Response JSON: $inchargeResponseBody',
                      );
                      print(
                        '� InchargeOrNot Response Keys: ${inchargeResponseBody.keys.toList()}',
                      );

                      // Update SQLite with incharge response data - Access nested responseData
                      dynamic responseData =
                          inchargeResponseBody['responseData'];
                      Map<String, dynamic> responseDataMap = {};

                      if (responseData is List && responseData.isNotEmpty) {
                        try {
                          responseDataMap =
                              responseData[0] as Map<String, dynamic>;
                        } catch (e) {
                          print(
                            "Error casting responseData list element to map: $e",
                          );
                        }
                      } else if (responseData is Map) {
                        responseDataMap = responseData as Map<String, dynamic>;
                      }

                      final projectName =
                          responseDataMap['projectName']?.toString() ?? '';
                      final projectId =
                          responseDataMap['projectId']?.toString() ?? '';
                      final productionHouse =
                          responseDataMap['productionHouse']?.toString() ?? '';
                      final productionTypeId =
                          responseDataMap['productionTypeId'] ??
                          0; // Assuming int

                      dynamic rawVmid =
                          responseDataMap['vmid'] ?? responseDataMap['vmId'];
                      int vmidVal = 0;
                      if (rawVmid is int) {
                        vmidVal = rawVmid;
                      } else if (rawVmid is String) {
                        vmidVal = int.tryParse(rawVmid) ?? 0;
                      }

                      print(
                        '🔍 Extracted values from InchargeOrNot responseData:',
                      );
                      print('🔍 projectName: "$projectName"');
                      print('🔍 projectId: "$projectId"');
                      print('🔍 productionHouse: "$productionHouse"');
                      print('🔍 productionTypeId: "$productionTypeId"');
                      print('🔍 vmid: "$vmidVal"');

                      // Always try to update, even with empty values for testing
                      print(' Attempting SQLite update...');
                      await LoginSQLiteHelper.updateDriverLoginData(
                        projectName,
                        projectId,
                        productionHouse,
                        productionTypeId,
                        vmidVal,
                      );
                      print('� SQLite update call completed');

                      if (projectName.isNotEmpty ||
                          projectId.isNotEmpty ||
                          productionHouse.isNotEmpty) {
                        print('✅ Updated SQLite with incharge response data');
                      } else {
                        print(
                          '⚠️ All incharge data fields are empty, but update was attempted',
                        );
                      }

                      // Conditional navigation based on responseData content
                      if (inchargeResponseBody['responseData'] != null &&
                          inchargeResponseBody['responseData'].toString() !=
                              '{}' &&
                          inchargeResponseBody['responseData']
                              .toString()
                              .isNotEmpty) {
                        print(
                          '✅ User is confirmed as Incharge, preparing project list',
                        );

                        // Parse the response data into a list of ProjectData
                        // The API might return a single object or a list
                        List<ProjectData> projects = [];
                        final responseData =
                            inchargeResponseBody['responseData'];

                        if (responseData is List) {
                          // If responseData is a list, convert each item to ProjectData
                          projects = responseData
                              .map(
                                (item) => ProjectData.fromJson(
                                  item as Map<String, dynamic>,
                                ),
                              )
                              .toList();
                          print(
                            '📋 Parsed ${projects.length} projects from API response',
                          );
                        } else if (responseData is Map) {
                          // If it's a single object, wrap it in a list
                          projects = [
                            ProjectData.fromJson(
                              responseData as Map<String, dynamic>,
                            ),
                          ];
                          print('📋 Parsed 1 project from API response');
                        }

                        // Update driver field to false for incharge
                        await LoginSQLiteHelper.updateDriverField(false);

                        // Navigate to ProjectListScreen
                        if (mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProjectListScreen(
                                // onProjectSelected: () {
                                //   // After project selection, navigate to the main route
                                //   Navigator.pushAndRemoveUntil(
                                //     context,
                                //     MaterialPageRoute(
                                //       builder: (context) =>
                                //           const RoutescreenforDubbingIncharge(),
                                //     ),
                                //     (route) => false,
                                //   );
                                // },
                              ),
                            ),
                          );
                        }
                      } else {
                        print('❌ Invalid or empty responseData');
                      }
                    } catch (e) {
                      print(
                        '❌ Error processing InchargeOrNot response JSON: $e',
                      );
                    }
                  } else {
                    print(
                      '❌ InchargeOrNot response status code: ${inchargeApiResponse['statusCode']}',
                    );
                  }
                } catch (e) {
                  print('❌ Error in InchargeOrNot API request: $e');
                }
            }
          } else {
            DialogHelper.showMessage(
              context,
              "Invalid response from server",
              "ok",
            );
          }
        } catch (e) {
          print("Error parsing login response: $e");
          DialogHelper.showMessage(
            context,
            "Failed to process login response",
            "ok",
          );
        }
      } else {
        try {
          final errorBody = json.decode(apiResponse['body']);
          setState(() {
            loginresponsebody = errorBody;
          });
          DialogHelper.showMessage(
            context,
            errorBody?['errordescription'] ?? "Login failed",
            "ok",
          );
        } catch (e) {
          print("Error parsing error response: $e");
          DialogHelper.showMessage(context, "Login failed", "ok");
        }
        print(apiResponse['body'] + "📊📊📊📊📊📊📊📊📊📊📊📊📊📊📊📊");
      }
    } catch (e) {
      print("Error in loginr(): $e");
      setState(() {
        _isLoading = false;
      });
      DialogHelper.showMessage(
        context,
        "Network error. Please try again.",
        "ok",
      );
    }
  }

  @override
  void dispose() {
    // Don't close database here - let it close naturally
    // _database?.close();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      print('🚀 Starting app initialization...');

      // Test SQLite functionality
      await LoginSQLiteHelper.testSQLite();

      // Load base URL
      print('🌐 Loading base URL...');
      await baseurl();
      print('✅ Base URL loaded');
    } catch (e) {
      print('❌ Error during app initialization: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      // Remove the extra AppBar so the background gradient can fill the
      // entire screen. Make the scaffold itself transparent.
      body: Stack(
        children: [
          // Subtle background overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF164AE9).withValues(alpha: 0.15),
                  Colors.white,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: screenHeight * 0.04),
                // Logo/Header
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: screenWidth * 0.22,
                        height: screenWidth * 0.22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            cinefo__logo,
                            // cinefoagent,
                            // cinefodriver,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        // 'Agent Login',
                        // 'Driver Login',
                        'Dubbing Login',
                        // 'Setting Login',
                        style: TextStyle(
                          fontSize: screenWidth * 0.055,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF164AE9),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.07,
                        ),
                        child: Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.06,
                              vertical: screenHeight * 0.04,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Login to Continue",
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.05,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.04),
                                TextFormField(
                                  controller: loginmobilenumber,
                                  keyboardType: TextInputType.phone,
                                  decoration: InputDecoration(
                                    labelText: 'Mobile Number',
                                    prefixIcon: Icon(
                                      Icons.phone,
                                      color: Color(0xFF164AE9),
                                    ),
                                    labelStyle: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.025),
                                TextFormField(
                                  controller: loginpassword,
                                  keyboardType: TextInputType.visiblePassword,
                                  obscureText: _obscureText,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: Icon(
                                      Icons.lock,
                                      color: Color(0xFF164AE9),
                                    ),
                                    labelStyle: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureText
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscureText = !_obscureText;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const ForgetPasswordScreen(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        color: Color(0xFF164AE9),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.03),
                                SizedBox(
                                  width: double.infinity,
                                  height: screenHeight * 0.07,
                                  child: ElevatedButton(
                                    onPressed: _isLoading
                                        ? null
                                        : () {
                                            loginr();
                                          },
                                    style:
                                        ElevatedButton.styleFrom(
                                          elevation: 4,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                          ),
                                          padding: EdgeInsets.zero,
                                          backgroundColor: null,
                                        ).copyWith(
                                          backgroundColor:
                                              WidgetStateProperty.resolveWith<
                                                Color?
                                              >((states) {
                                                if (states.contains(
                                                  WidgetState.disabled,
                                                )) {
                                                  return Colors.grey[400];
                                                }
                                                return null;
                                              }),
                                        ),
                                    child: Ink(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0xFF164AE9),
                                            Color(0xFF4F8CFF),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: Container(
                                        alignment: Alignment.center,
                                        child: _isLoading
                                            ? CircularProgressIndicator(
                                                color: Colors.white,
                                              )
                                            : Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    'Login',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize:
                                                          screenWidth * 0.045,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  SizedBox(width: 8),
                                                  Icon(
                                                    Icons.login,
                                                    color: Colors.white,
                                                  ),
                                                ],
                                              ),
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
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
                  child: Text(
                    'V.4.0.2',
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
