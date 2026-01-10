import 'dart:convert';
import 'package:flutter/material.dart';
import '../report/callsheetmembers.dart';
import 'offline_callsheet_detail.dart';
import '../../ApiCalls/apicall.dart' as apicalls;
import '../../variables.dart';
import 'CreateCallsheetScreen.dart';

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

class CallsheetScreen extends StatefulWidget {
  const CallsheetScreen({super.key});

  @override
  State<CallsheetScreen> createState() => _CallsheetScreenState();
}

class _CallsheetScreenState extends State<CallsheetScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> callSheetData = [];
  String global_projectidString = "";
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAndCallAPI();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasInitialized) {
      // Refresh data when returning to this page
      _initializeAndCallAPI();
    } else {
      _hasInitialized = true;
    }
  }

  Future<void> _initializeAndCallAPI() async {
    setState(() => _isLoading = true);
    try {
      await apicalls.fetchloginDataFromSqlite();

      // Fetch callsheet data using fetchcallsheetapi
      final projId = projectId != null ? int.tryParse(projectId!) ?? 0 : 0;

      print('📋 Fetching callsheets for project: $projId');
      final result = await apicalls.fetchcallsheetapi(projectid: projId);

      print('✅ fetchcallsheetapi Status: ${result['statusCode']}');
      _parseCallSheetResponse(result['body']);
    } catch (e) {
      print('❌ Error loading callsheet data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _parseCallSheetResponse(dynamic responseBody) {
    try {
      dynamic response = responseBody is String
          ? jsonDecode(responseBody)
          : responseBody;
      List<dynamic> rawData = [];
      if (response is List) {
        rawData = response;
      } else if (response is Map && response['responseData'] != null) {
        final resData = response['responseData'];
        if (resData is List) {
          rawData = resData;
        } else if (resData is Map) {
          bool foundList = false;
          resData.forEach((key, value) {
            if (!foundList && value is List) {
              rawData = value;
              foundList = true;
            }
          });
          if (!foundList) rawData = [resData];
        }
      }

      setState(() {
        callSheetData = rawData
            .where((item) => item != null && item is Map)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      });

      if (callSheetData.isNotEmpty) {
        global_projectidString =
            callSheetData[0]['projectId']?.toString() ??
            callSheetData[0]['projectid']?.toString() ??
            "";
      }
    } catch (e) {
      print('❌ Error parsing callsheet response: $e');
    }
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return "N/A";
    String dateStr = dateValue.toString();
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

    return Scaffold(
      backgroundColor: const Color(0xFF2B5682),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: responsive.sh(56),
        title: Text(
          "CallSheet",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: responsive.sp(22),
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: responsive.sw(16)),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withOpacity(0.8),
                  width: responsive.sw(1.5),
                ),
                borderRadius: BorderRadius.circular(responsive.radius(10)),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.add,
                  color: Colors.white,
                  size: responsive.iconSize(28),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateCallsheetScreen(),
                    ),
                  ).then((value) => _initializeAndCallAPI());
                },
              ),
            ),
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(
              child: SizedBox(
                width: responsive.sw(40),
                height: responsive.sw(40),
                child: const CircularProgressIndicator(color: Colors.white),
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: responsive.sw(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: responsive.sh(10)),
                    Text(
                      "Today's Schedule",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: responsive.sp(20),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: responsive.sh(30)),
                    if (callSheetData.isEmpty)
                      _buildEmptyState(responsive)
                    else
                      ...callSheetData.map(
                        (callSheet) =>
                            _buildCallSheetCard(context, callSheet, responsive),
                      ),
                    SizedBox(height: responsive.hp(12)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildEmptyState(ResponsiveHelper responsive) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: responsive.sh(40),
          horizontal: responsive.sw(20),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(responsive.radius(25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: responsive.sw(10),
              offset: Offset(0, responsive.sh(5)),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Text(
                "Callsheet",
                style: TextStyle(
                  fontSize: responsive.sp(18),
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2B5682),
                ),
              ),
            ),
            SizedBox(height: responsive.sh(20)),
            Icon(
              Icons.description_outlined,
              size: responsive.iconSize(80),
              color: Colors.grey.withOpacity(0.5),
            ),
            SizedBox(height: responsive.sh(20)),
            Text(
              "No call sheet available",
              style: TextStyle(
                fontSize: responsive.sp(18),
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: responsive.sh(8)),
            Text(
              "Create a call sheet to see it here",
              style: TextStyle(fontSize: responsive.sp(14), color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallSheetCard(
    BuildContext context,
    Map<String, dynamic> callSheet,
    ResponsiveHelper responsive,
  ) {
    final String callSheetId =
        (callSheet['callSheetId'] ??
                callSheet['callsheetid'] ??
                callSheet['id'] ??
                callSheet['v5'] ??
                callSheet['v1'] ??
                callSheet['callsheetId'])
            ?.toString() ??
        "N/A";
    final String callSheetNo =
        (callSheet['callSheetNo'] ??
                callSheet['callsheetno'] ??
                callSheet['no'] ??
                callSheet['v4'] ??
                callSheet['v2'] ??
                callSheet['callsheetNo'])
            ?.toString() ??
        "N/A";
    final String projectName =
        (callSheet['projectName'] ??
                callSheet['projectname'] ??
                callSheet['MovieName'] ??
                callSheet['moviename'] ??
                callSheet['v3'])
            ?.toString() ??
        "N/A";
    final String date = _formatDate(
      callSheet['date'] ??
          callSheet['callsheetDate'] ??
          callSheet['callsheetdate'] ??
          callSheet['v11'],
    );
    final String shift =
        (callSheet['shift'] ??
                callSheet['shiftName'] ??
                callSheet['shiftname'] ??
                callSheet['v13'])
            ?.toString() ??
        "N/A";
    final String status =
        (callSheet['callsheetStatus'] ??
                callSheet['status'] ??
                callSheet['callsheet_status'] ??
                callSheet['v14'])
            ?.toString() ??
        "N/A";

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OfflineCallsheetDetailScreen(callsheet: callSheet),
          ),
        ).then((value) => _initializeAndCallAPI());
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
                    color: Colors.grey,
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
                    color: Colors.grey,
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
}
