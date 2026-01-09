import 'dart:convert';
import 'package:flutter/material.dart';
import '../report/callsheetmembers.dart';
import 'offline_callsheet_detail.dart';
import '../../ApiCalls/apicall.dart' as apicalls;
import '../../variables.dart';
import 'CreateCallsheetScreen.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFF2B5682),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "CallSheet",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withOpacity(0.8),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                icon: const Icon(Icons.add, color: Colors.white, size: 28),
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
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    const Text(
                      "Today's Schedule",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 30),
                    if (callSheetData.isEmpty)
                      _buildEmptyState()
                    else
                      ...callSheetData.map(
                        (callSheet) => _buildCallSheetCard(context, callSheet),
                      ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Align(
              alignment: Alignment.topLeft,
              child: Text(
                "Callsheet",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2B5682),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Icon(
              Icons.description_outlined,
              size: 80,
              color: Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 20),
            const Text(
              "No call sheet available",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Create a call sheet to see it here",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallSheetCard(
    BuildContext context,
    Map<String, dynamic> callSheet,
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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF4A6FA5).withOpacity(0.1),
                    const Color(0xFF2E4B73).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Call Sheet #$callSheetNo",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF2B5682),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(status),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.movie, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                const Text(
                  "Project: ",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Expanded(
                  child: Text(
                    projectName,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.badge, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  "ID: $callSheetId",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF355E8C),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                const Text(
                  "Shift: ",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Expanded(
                  child: Text(
                    shift,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
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
