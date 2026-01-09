import 'dart:convert';

import 'package:cinefo_dubbing/Route/RouteScreenfordubbingincharge.dart';
import 'package:cinefo_dubbing/colorcode/colorcode.dart';
import 'package:cinefo_dubbing/sessionexpired.dart';
import 'package:cinefo_dubbing/variables.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../../ApiCalls/apicall.dart';

class ApprovalScreen extends StatefulWidget {
  final Map<String, dynamic> callSheet;
  final int approvalid; // initial value: 0 = waiting, 1 = approved
  const ApprovalScreen(this.approvalid, {Key? key, required this.callSheet})
    : super(key: key);
  @override
  State<ApprovalScreen> createState() => _ApprovalScreenState();
}

class _ApprovalScreenState extends State<ApprovalScreen> {
  Map<String, dynamic>? logindata;
  int approvalid = 0; // runtime state
  Database? _database;
  bool _isLoading = false; // new: show spinner while refreshing

  @override
  void initState() {
    super.initState();
    // initialize state from widget properties
    approvalid = widget.approvalid;
    // print callsheet as requested
    print('Callsheet: charles ${widget.callSheet}');
    // call API initializer
    _initializeAndCallAPI();
  }

  Future<void> _initializeAndCallAPI() async {
    try {
      // First fetch the login_data table values
      await fetchloginDataFromSqlite();

      if (globalloginData != null) {
        // Ensure callsheetStatusId is an int (handle string values)

        // Normalize response body to a Map so we can safely inspect responseData
        try {
          // Parse callsheet id from the widget.callSheet (handle different key casings)
          final dynamic rawId = widget.callSheet['callsheetId'] ??
              widget.callSheet['callsheetid'] ??
              widget.callSheet['callSheetId'] ??
              widget.callSheet['CallsheetId'];
              
          final int callsheetId = rawId is int
              ? rawId : (rawId is String ? int.tryParse(rawId) ?? 0 : 0);
              

          // Parse project id from widget.callSheet (may be provided by caller)
          final dynamic rawProjectId =
              widget.callSheet['projectid'] ??
              widget.callSheet['projectId'] ??
              widget.callSheet['projectID'] ??
              widget.callSheet['ProjectId'];
          final int projectId = rawProjectId is int
              ? rawProjectId
              : (rawProjectId is String ? int.tryParse(rawProjectId) ?? 0 : 0);

          // Call the second approval API and log the response (safe await with try/catch)
          final result2 = await raiserequestapi(
            projectId,
            callsheetid: callsheetId,
            vsid: globalloginData?['vsid'] ?? '',
          );
          print(' result: $result2');

          // Check for session expiration
          if (!result2['success']) {
            try {
              Map error = jsonDecode(result2['body']);
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

          // Parse result2 body safely to inspect responseData.Statusid
          dynamic body2 = result2['body'];
          Map<String, dynamic>? responseBody2;
          if (body2 == null) {
            responseBody2 = null;
          } else if (body2 is String) {
            try {
              final parsed2 = jsonDecode(body2);
              if (parsed2 is Map<String, dynamic>) {
                responseBody2 = parsed2;
              }
            } catch (e) {
              responseBody2 = null;
            }
          } else if (body2 is Map<String, dynamic>) {
            responseBody2 = body2;
          }

          // Extract Statusid robustly (different possible key casings) and check for value 2
          int statusId = 0;
          if (responseBody2 != null && responseBody2['responseData'] != null) {
            final dynamic respData = responseBody2['responseData'];
            final dynamic rawStatusId =
                respData['Statusid'] ??
                respData['StatusId'] ??
                respData['statusid'] ??
                respData['statusId'] ??
                respData['Status'] ??
                respData['status'];

            if (rawStatusId is int) {
              statusId = rawStatusId;
            } else if (rawStatusId is String) {
              statusId = int.tryParse(rawStatusId) ?? 0;
            }
          }

          if (statusId == 2) {
            setState(() {
              print("success charles");
              approvalid = 1;
            });
          } else {
            print(
              'Approval not final (Statusid=$statusId), keeping approvalid=0',
            );
          }
        } catch (e) {
          print('Error calling approvalofproductionmanager2api: $e');
        }

        // Do not change approvalid here; it is set only when statusId == 2 above.
      }
    } catch (e) {
      print('Error initializing: $e');
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize database connection
  Future<Database> _initDatabase() async {
    String dbPath = path.join(await getDatabasesPath(), 'production_login.db');
    return await openDatabase(
      dbPath,
      version: 1,
      // This just connects to existing database
    );
  }

  Future<Map<String, dynamic>?> _getLoginData() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'login_data',
        orderBy: 'id ASC',
        limit: 1,
      );

      if (maps.isNotEmpty) {
        print('📊 Login data found: ${maps.first}');
        return maps.first;
      }
      print('🔍 No login data found in table');
      return null;
    } catch (e) {
      print('❌ Error getting login data: $e');
      return null;
    }
  }

  // Handler for the refresh button. Shows a spinner while refreshing.
  Future<void> _onRefreshPressed() async {
    if (_isLoading) return; // prevent double taps
    setState(() {
      _isLoading = true;
    });
    try {
      await _initializeAndCallAPI();
      // Optional: give user feedback
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Refreshed')));
    } catch (e) {
      print('Error during manual refresh: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Refresh failed')));
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
    if (approvalid == 0) {
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

    // If approved, navigate to CallsheetDetailScreen immediately
    // Use a post-frame callback so navigation happens after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              RoutescreenforDubbingIncharge(callsheet: widget.callSheet),
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
