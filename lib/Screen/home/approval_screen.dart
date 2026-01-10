import 'dart:convert';

import 'package:cinefo_dubbing/Route/RouteScreenfordubbingincharge.dart';
import 'package:cinefo_dubbing/colorcode/colorcode.dart';
import 'package:cinefo_dubbing/sessionexpired.dart';
import 'package:cinefo_dubbing/variables.dart';
import 'package:flutter/material.dart';

import '../../ApiCalls/apicall.dart';

class ApprovalScreen extends StatefulWidget {
  final int projectid;
  const ApprovalScreen(this.projectid, {Key? key}) : super(key: key);
  
  @override
  State<ApprovalScreen> createState() => _ApprovalScreenState();
}

class _ApprovalScreenState extends State<ApprovalScreen> {
  bool _isApproved = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkApprovalStatus();
  }

  Future<void> _checkApprovalStatus() async {
    try {
      await fetchloginDataFromSqlite();

      if (globalloginData != null) {
        final result = await raiserequestapi(widget.projectid);
        print('Approval result: $result');

        // Check for session expiration
        if (!result['success']) {
          try {
            Map error = jsonDecode(result['body']);
            if (error['errordescription'] == "Session Expired") {
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Sessionexpired(),
                  ),
                );
              }
              return;
            }
          } catch (e) {
            print('Error parsing error response: $e');
          }
        }

        // Parse response to check Statusid
        dynamic body = result['body'];
        Map<String, dynamic>? responseBody;
        
        if (body is String) {
          try {
            final parsed = jsonDecode(body);
            if (parsed is Map<String, dynamic>) {
              responseBody = parsed;
            }
          } catch (e) {
            responseBody = null;
          }
        } else if (body is Map<String, dynamic>) {
          responseBody = body;
        }

        // Extract Statusid from responseData
        int statusId = 0;
        if (responseBody != null && responseBody['responseData'] != null) {
          final dynamic respData = responseBody['responseData'];
          final dynamic rawStatusId =
              respData['Statusid'];

          if (rawStatusId is int) {
            statusId = rawStatusId;
          } else if (rawStatusId is String) {
            statusId = int.tryParse(rawStatusId) ?? 0;
          }
        }

        if (statusId == 2) {
          setState(() {
            print("Approved! Statusid: $statusId");
            _isApproved = true;
          });
        } else {
          print('Not approved yet (Statusid=$statusId)');
        }
      }
    } catch (e) {
      print('Error checking approval status: $e');
    }
  }

  Future<void> _onRefreshPressed() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });
    try {
      await _checkApprovalStatus();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Refreshed')),
      );
    } catch (e) {
      print('Error during manual refresh: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Refresh failed')),
        );
      }
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (!_isApproved) {
      return Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: AppColors.gradientBackground,
          child: SafeArea(
            child: Column(
              children: [
                // Custom App Bar
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: screenHeight * 0.015,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: EdgeInsets.all(screenWidth * 0.02),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(screenWidth * 0.025),
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: screenWidth * 0.05,
                          ),
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.04),
                      Text(
                        'Approval Status',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.05,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Main Content
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(screenWidth * 0.06),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Animated waiting icon container
                          Container(
                            width: screenWidth * 0.3,
                            height: screenWidth * 0.3,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: _isLoading
                                  ? SizedBox(
                                      width: screenWidth * 0.125,
                                      height: screenWidth * 0.125,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 3,
                                      ),
                                    )
                                  : Icon(
                                      Icons.hourglass_top_rounded,
                                      size: screenWidth * 0.15,
                                      color: Colors.white,
                                    ),
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.04),
                          // Status badge
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.04,
                              vertical: screenHeight * 0.01,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(screenWidth * 0.05),
                              border: Border.all(
                                color: Colors.orange.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.pending_outlined,
                                  color: Colors.orange,
                                  size: screenWidth * 0.045,
                                ),
                                SizedBox(width: screenWidth * 0.02),
                                Text(
                                  'Pending Approval',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: screenWidth * 0.035,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.03),
                          // Main message
                          Text(
                            'Waiting for Confirmation',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: screenWidth * 0.06,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.015),
                          Text(
                            'Your approval request has been sent to the Production Manager. Please wait until they confirm your approval.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: screenWidth * 0.0375,
                              color: Colors.white.withOpacity(0.8),
                              height: 1.5,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.05),
                          // Refresh button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _onRefreshPressed,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.primaryDark,
                                disabledBackgroundColor: Colors.white
                                    .withOpacity(0.5),
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.08,
                                  vertical: screenHeight * 0.02,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                                ),
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_isLoading) ...[
                                    SizedBox(
                                      width: screenWidth * 0.05,
                                      height: screenWidth * 0.05,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primaryDark,
                                      ),
                                    ),
                                    SizedBox(width: screenWidth * 0.03),
                                    Text(
                                      'Checking...',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.04,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ] else ...[
                                    Icon(Icons.refresh_rounded, size: screenWidth * 0.055),
                                    SizedBox(width: screenWidth * 0.025),
                                    Text(
                                      'Check Status',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.04,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          // Info text
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: screenWidth * 0.04,
                                color: Colors.white.withOpacity(0.6),
                              ),
                              SizedBox(width: screenWidth * 0.015),
                              Text(
                                'Tap to refresh and check approval status',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.03,
                                  color: Colors.white.withOpacity(0.6),
                                ),
                              ),
                            ],
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
      );
    }

    // If approved (Statusid == 2), navigate to RoutescreenforDubbingIncharge
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => RoutescreenforDubbingIncharge(),
        ),
      );
    });

    // While navigation happens, render an empty scaffold with gradient background
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: AppColors.gradientBackground,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      ),
    );
  }
}
