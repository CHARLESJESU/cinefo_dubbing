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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Approval Status',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
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
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Animated waiting icon container
                          Container(
                            width: 120,
                            height: 120,
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
                                  ? const SizedBox(
                                      width: 50,
                                      height: 50,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 3,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.hourglass_top_rounded,
                                      size: 60,
                                      color: Colors.white,
                                    ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.orange.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.pending_outlined,
                                  color: Colors.orange,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Pending Approval',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Main message
                          const Text(
                            'Waiting for Confirmation',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Your approval request has been sent to the Production Manager. Please wait until they confirm your approval.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white.withOpacity(0.8),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 40),
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_isLoading) ...[
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primaryDark,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Checking...',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ] else ...[
                                    const Icon(Icons.refresh_rounded, size: 22),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'Check Status',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Info text
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 16,
                                color: Colors.white.withOpacity(0.6),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Tap to refresh and check approval status',
                                style: TextStyle(
                                  fontSize: 12,
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