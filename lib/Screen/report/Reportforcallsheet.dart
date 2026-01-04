import 'dart:convert';
import 'package:flutter/material.dart';
import 'callsheetmembers.dart';
import '../../ApiCalls/apicall.dart' as apicalls;
import '../../variables.dart' as vars;

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

      // Then call lookup callsheet API using projectId
      final int pid = int.tryParse(vars.projectId ?? '0') ?? 0;
      final String vs = vars.vsid ?? '';
      var result = await apicalls.lookupcallsheetapi(projectid: pid, vsid: vs);
      print("🚗 lookupcallsheetapi Response: ${result['body']}");
      print("🔍 API Result Success: ${result['success']}");

      // If lookup fails (server 503), fallback to agentreportapi() which may return usable data
      if (result['success'] != true) {
        print('⚠️ lookupcallsheetapi failed, falling back to agentreportapi()');
        final agentResult = await apicalls.agentreportapi();
        print("🚗 agentreportapi Response: ${agentResult['body']}");
        // prefer agentResult body if lookup failed
        result = agentResult;
      }

      // Parse the response and extract callsheet data
      _parseCallSheetResponse(result['body']);

      if (callSheetData.isNotEmpty) {
        _showSuccess('Callsheet data loaded successfully!');
      }
    } catch (e) {
      print('❌ Error calling API: $e');
      _showError('Failed to load callsheet data');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Parse the API response and extract callsheet data
  void _parseCallSheetResponse(dynamic responseBody) {
    try {
      dynamic response;

      // Check if responseBody is already a object or needs to be decoded
      if (responseBody is String) {
        response = jsonDecode(responseBody);
      } else {
        response = responseBody;
      }

      List<dynamic> rawData = [];

      if (response is List) {
        rawData = response;
      } else if (response is Map && response['responseData'] != null) {
        final resData = response['responseData'];
        if (resData is List) {
          rawData = resData;
        } else if (resData is Map) {
          // Look for the first list found inside the Map
          bool foundList = false;
          resData.forEach((key, value) {
            if (!foundList && value is List) {
              rawData = value;
              foundList = true;
            }
          });
          // Fallback: wrap the map itself if no list found
          if (!foundList) rawData = [resData];
        }
      }

      if (rawData.isNotEmpty && rawData[0] is Map) {
        print("🔍 First item keys: ${rawData[0].keys.toList()}");
        print("🔍 First item values: ${rawData[0].values.toList()}");
      }

      if (rawData.isEmpty && response is Map && response['message'] != null) {
        String msg = response['message'].toString();
        if (msg.toLowerCase() != "success") {
          _showError(msg);
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
      setState(() {
        callSheetData = [];
      });
      _showError('Failed to parse server response');
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
    return Scaffold(
      backgroundColor: const Color(0xFF2B5682),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Reports",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
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
                      Center(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 40,
                            horizontal: 20,
                          ),
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
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
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
                          ...callSheetData.map(
                            (callSheet) =>
                                _buildCallSheetCard(context, callSheet),
                          ),
                        ],
                      ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
    );
  }

  // Build call sheet card widget similar to incharge report style
  Widget _buildCallSheetCard(
    BuildContext context,
    Map<String, dynamic> callSheet,
  ) {
    // Extract fields from callSheet map - handle camelCase, lowercase, underscores, and generic v-keys
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
        // Navigate to the full callsheet detail screen
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
            // Header with gradient background
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
            // Project Name
            Row(
              children: [
                Icon(Icons.movie, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  "Project: ",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
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
            // Call Sheet ID and Created Date
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
            // Shift Information
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  "Shift: ",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
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
