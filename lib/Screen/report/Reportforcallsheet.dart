import 'dart:convert';
import 'package:cinefo_dubbing/variables.dart';
import 'package:flutter/material.dart';
import 'callsheetmembers.dart';
import '../../ApiCalls/apicall.dart' as apicalls;

// Responsive helper class
class ResponsiveHelper {
  final BuildContext context;
  late double screenWidth;
  late double screenHeight;

  ResponsiveHelper(this.context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
  }

  static const double baseWidth = 393.0;
  static const double baseHeight = 852.0;

  double wp(double percentage) => screenWidth * percentage / 100;
  double hp(double percentage) => screenHeight * percentage / 100;
  double sw(double size) => size * screenWidth / baseWidth;
  double sh(double size) => size * screenHeight / baseHeight;
  double sp(double size) {
    double scaleFactor = screenWidth / baseWidth;
    return (size * scaleFactor).clamp(size * 0.8, size * 1.3);
  }

  double radius(double size) => sw(size);
  double iconSize(double size) => sw(size).clamp(size * 0.8, size * 1.5);
  bool get isSmallPhone => screenWidth < 360;
  bool get isTablet => screenWidth >= 600;
}

class Reportforcallsheet extends StatefulWidget {
  const Reportforcallsheet({super.key});

  @override
  State<Reportforcallsheet> createState() => _ReportforcallsheeteState();
}

class _ReportforcallsheeteState extends State<Reportforcallsheet> {
  bool _isLoading = false;
  List<Map<String, dynamic>> callSheetData = [];
  String global_projectidString = "";

  @override
  void initState() {
    super.initState();
    _initializeAndCallAPI();
  }

  // Initialize and call API
  Future<void> _initializeAndCallAPI() async {
    setState(() => _isLoading = true);

    try {
      // First fetch login data from SQLite
      await apicalls.fetchloginDataFromSqlite();

      // Then call agent report API with projectId
      final projectIdInt = int.tryParse(projectId.toString()) ?? 0;
      final result = await apicalls.agentreportapi(projectIdInt);
      print("🚗 Agent Report API Response: ${result['body']}");
      print("🔍 API Result Success: ${result['success']}");
      print("🔍 API Result Keys: ${result.keys}");

      // Parse the response and extract callsheet data
      _parseCallSheetResponse(result['body']);

      if (callSheetData.isNotEmpty) {
        _showSuccess('Callsheet data loaded successfully!');
      }
    } catch (e) {
      print('❌ Error calling API: $e');
      _showError('Error loading callsheet data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Parse the API response and extract callsheet data
  void _parseCallSheetResponse(dynamic responseBody) {
    print('🔧 Starting to parse response...');
    print('🔧 Response body type: ${responseBody.runtimeType}');
    print('🔧 Response body: $responseBody');

    try {
      Map<String, dynamic> response;

      // Check if responseBody is already a Map or needs to be decoded
      if (responseBody is String) {
        response = jsonDecode(responseBody);
      } else if (responseBody is Map<String, dynamic>) {
        response = responseBody;
      } else {
        print('❌ Unexpected response type: ${responseBody.runtimeType}');
        setState(() {
          callSheetData = [];
        });
        return;
      }

      print('🔧 Decoded JSON successfully');
      print('🔧 Response keys: ${response.keys}');
      print('🔧 responseData exists: ${response.containsKey('responseData')}');
      print('🔧 responseData value: ${response['responseData']}');
      print('🔧 responseData type: ${response['responseData']?.runtimeType}');

      if (response['responseData'] != null &&
          response['responseData'] is List) {
        final List<dynamic> rawData = response['responseData'] as List;
        print('🔧 responseData length: ${rawData.length}');

        setState(() {
          callSheetData = rawData
              .where((item) => item != null)
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
        });

        print('📋 Parsed ${callSheetData.length} callsheet records');

        if (callSheetData.isNotEmpty) {
          print('📋 First record: ${callSheetData[0]}');
          global_projectidString =
              callSheetData[0]['projectId']?.toString() ?? "";
          print('📋 Set global projectId: $global_projectidString');
        }
      } else {
        print('⚠️ responseData is null or not a List');
        print('⚠️ responseData value: ${response['responseData']}');
        setState(() {
          callSheetData = [];
        });
      }
    } catch (e, stackTrace) {
      print('❌ Error parsing callsheet response: $e');
      print('❌ Stack trace: $stackTrace');
      setState(() {
        callSheetData = [];
      });
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // Format date from YYYYMMDD to DD-MM-YYYY
  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return "N/A";

    String dateStr = dateValue.toString();

    // If it's in YYYYMMDD format (8 digits)
    if (dateStr.length == 8 && int.tryParse(dateStr) != null) {
      String year = dateStr.substring(0, 4);
      String month = dateStr.substring(4, 6);
      String day = dateStr.substring(6, 8);
      return "$day-$month-$year";
    }

    return dateStr;
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
          appBar: AppBar(
            automaticallyImplyLeading: false,
            toolbarHeight: responsive.sh(56),
            title: Text(
              "Call Sheets Report",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: responsive.sp(18),
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(responsive.sw(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: responsive.hp(3.5)),
                  // Call sheets list section
                  if (_isLoading)
                    Center(
                      child: Container(
                        padding: EdgeInsets.all(responsive.sw(40)),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            responsive.radius(15),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: responsive.sw(6),
                              offset: Offset(0, responsive.sh(2)),
                            ),
                          ],
                        ),
                        child: SizedBox(
                          width: responsive.sw(40),
                          height: responsive.sw(40),
                          child: const CircularProgressIndicator(
                            color: Color(0xFF2B5682),
                          ),
                        ),
                      ),
                    )
                  else if (callSheetData.isEmpty)
                    Center(
                      child: Container(
                        padding: EdgeInsets.all(responsive.sw(40)),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            responsive.radius(15),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: responsive.sw(6),
                              offset: Offset(0, responsive.sh(2)),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.description_outlined,
                              size: responsive.iconSize(60),
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: responsive.sh(16)),
                            Text(
                              "No Call Sheets Available",
                              style: TextStyle(
                                fontSize: responsive.sp(16),
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Call Sheets Section
                        if (callSheetData.isNotEmpty) ...[
                          Padding(
                            padding: EdgeInsets.only(bottom: responsive.sh(12)),
                            child: Text(
                              "Report List",
                              style: TextStyle(
                                fontSize: responsive.sp(18),
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          ...callSheetData.map(
                            (callSheet) => _buildCallSheetCard(
                              context,
                              callSheet,
                              responsive,
                            ),
                          ),
                        ],
                      ],
                    ),
                  // Add extra bottom padding to prevent content from being hidden by navigation
                  SizedBox(height: responsive.hp(12)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Build call sheet card widget similar to incharge report style
  Widget _buildCallSheetCard(
    BuildContext context,
    Map<String, dynamic> callSheet,
    ResponsiveHelper responsive,
  ) {
    // Extract fields from callSheet map
    final String callSheetId = callSheet['callSheetId']?.toString() ?? "N/A";
    final String callSheetNo = callSheet['callSheetNo']?.toString() ?? "N/A";
    final String projectName = callSheet['projectName']?.toString() ?? "N/A";
    final String date = _formatDate(callSheet['date']);
    final String shift = callSheet['shift']?.toString() ?? "N/A";
    final String status = callSheet['callsheetStatus']?.toString() ?? "N/A";
    return GestureDetector(
      onTap: () {
        // Navigate to the full callsheet detail screen (new file)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Callsheetmembers(
              projectId: global_projectidString,
              maincallsheetid: callSheetId,
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: responsive.sh(12)),
        padding: EdgeInsets.all(responsive.sw(16)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(responsive.radius(12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: responsive.sw(4),
              offset: Offset(0, responsive.sh(2)),
            ),
          ],
          border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with gradient background
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.sw(12),
                vertical: responsive.sh(8),
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF4A6FA5).withOpacity(0.1),
                    const Color(0xFF2E4B73).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(responsive.radius(8)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Call Sheet #$callSheetNo",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: responsive.sp(16),
                        color: const Color(0xFF2B5682),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: responsive.sw(8),
                      vertical: responsive.sh(4),
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(responsive.radius(6)),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: responsive.sp(12),
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(status),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: responsive.sh(12)),
            // Project Name
            Row(
              children: [
                Icon(
                  Icons.movie,
                  size: responsive.iconSize(16),
                  color: Colors.grey[600],
                ),
                SizedBox(width: responsive.sw(4)),
                Text(
                  "Project: ",
                  style: TextStyle(
                    fontSize: responsive.sp(14),
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Expanded(
                  child: Text(
                    projectName,
                    style: TextStyle(
                      fontSize: responsive.sp(14),
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: responsive.sh(8)),
            // Call Sheet ID and Created Date
            Row(
              children: [
                Icon(
                  Icons.badge,
                  size: responsive.iconSize(16),
                  color: Colors.grey[600],
                ),
                SizedBox(width: responsive.sw(4)),
                Text(
                  "ID: $callSheetId",
                  style: TextStyle(
                    fontSize: responsive.sp(14),
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.calendar_today,
                  size: responsive.iconSize(16),
                  color: Colors.grey[600],
                ),
                SizedBox(width: responsive.sw(4)),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: responsive.sp(14),
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF355E8C),
                  ),
                ),
              ],
            ),
            SizedBox(height: responsive.sh(8)),
            // Shift Information
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: responsive.iconSize(16),
                  color: Colors.grey[600],
                ),
                SizedBox(width: responsive.sw(4)),
                Text(
                  "Shift: ",
                  style: TextStyle(
                    fontSize: responsive.sp(14),
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Expanded(
                  child: Text(
                    shift,
                    style: TextStyle(
                      fontSize: responsive.sp(14),
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'closed':
        return Colors.green;
      case 'in-progress':
      case 'active':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
