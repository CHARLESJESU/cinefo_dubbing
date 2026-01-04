// Callsheet Attendance Details Screen
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../ApiCalls/apicall.dart';
import '../../sessionexpired.dart';
import '../../variables.dart';

class Callsheetmembers extends StatefulWidget {
  final String projectId;
  final String maincallsheetid;

  const Callsheetmembers({
    super.key,
    required this.projectId,
    required this.maincallsheetid,
  });

  @override
  State<Callsheetmembers> createState() => _CallsheetmembersState();
}

class _CallsheetmembersState extends State<Callsheetmembers> {
  List<AttendanceEntry> reportData = [];
  bool isLoading = true;

  Future<void> reportsscreen() async {
    print(
      '📋 Fetching attendance report for callsheet: ${widget.maincallsheetid}',
    );
    print('🔍 Unit ID: $agentunitid');
    print('🔍 VSID: ${vsid ?? ''}');

    await fetchloginDataFromSqlite();

    try {
      // Call attendencereportapi with callsheet ID
      final apiResult = await attendencereportapi(
        callsheetid: widget.maincallsheetid,
        unitIdParam: agentunitid,
      );

      print(
        '📊 attendencereportapi Response Status: ${apiResult['statusCode']}',
      );
      print('📊 attendencereportapi Success: ${apiResult['success']}');
      print('📊 attendencereportapi Body: ${apiResult['body']}');

      if (apiResult['success'] == true) {
        final decoded = jsonDecode(apiResult['body']);
        print("✅ API Response decoded: $decoded");

        // Check if API returned an error status (even with HTTP 200)
        final apiStatus = decoded['status']?.toString() ?? '0';

        if (apiStatus == '1028' || decoded['responseData'] == null) {
          // API returned an error status or no data
          print(
            '⚠️ API returned error or no data - Status: $apiStatus, Message: ${decoded['message']}',
          );
          final msg =
              decoded['message']?.toString() ?? 'No attendance data available';
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(msg),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 4),
              ),
            );
          }
          setState(() {
            reportData = [];
            isLoading = false;
          });
        } else if (decoded['responseData'] != null) {
          List<AttendanceEntry> entries = (decoded['responseData'] as List)
              .map((e) => AttendanceEntry.fromJson(e))
              .toList();
          setState(() {
            reportData = entries;
            isLoading = false;
          });
          print('✅ Successfully loaded ${entries.length} attendance entries');
        } else {
          setState(() {
            reportData = [];
            isLoading = false;
          });
        }
      } else {
        // API call failed
        print('❌ API call failed with status: ${apiResult['statusCode']}');
        try {
          final error = jsonDecode(apiResult['body']);
          print('❌ Error response: $error');

          if (error['errordescription'] == "Session Expired") {
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Sessionexpired()),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    error['message']?.toString() ??
                        'Failed to fetch attendance data',
                  ),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          }
        } catch (e) {
          print('❌ Error parsing error response: $e');
          if (mounted) {
            final err =
                apiResult['errorMessage'] ?? 'Failed to fetch attendance data';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(err),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }

        setState(() {
          reportData = [];
          isLoading = false;
        });
      }
    } catch (e) {
      print("❌ Exception in reportsscreen: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to fetch attendance data'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      setState(() => isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    reportsscreen();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Container(
                width: MediaQuery.of(context).size.width,
                height: 80,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.only(left: 30, top: 20),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back),
                      ),
                      const SizedBox(width: 20),
                      const Text(
                        "Callsheet Attendance Details",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(228, 215, 248, 1),
                        border: Border.all(
                          color: const Color.fromRGBO(131, 77, 218, 1),
                        ),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Code',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color.fromRGBO(131, 77, 218, 1),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              'Name',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color.fromRGBO(131, 77, 218, 1),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'In Time',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color.fromRGBO(131, 77, 218, 1),
                              ),
                            ),
                          ),
                          SizedBox(width: 20),
                          Expanded(
                            child: Text(
                              'Out Time',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color.fromRGBO(131, 77, 218, 1),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        itemCount: reportData.length,
                        itemBuilder: (context, index) {
                          final entry = reportData[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(entry.code ?? "--"),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(entry.memberName),
                                ),
                                Expanded(child: Text(entry.inTime ?? "--")),
                                const SizedBox(width: 20),
                                Expanded(child: Text(entry.outTime ?? "--")),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AttendanceEntry {
  final String memberName;
  final String? code;
  final String? inTime;
  final String? outTime;

  AttendanceEntry({
    required this.memberName,
    this.code,
    this.inTime,
    this.outTime,
  });

  factory AttendanceEntry.fromJson(Map<String, dynamic> json) {
    String unitCode = json['unitcode']?.toString() ?? '';
    String memberCodeCode = json['membercodeCode']?.toString() ?? '';
    String combinedCode = unitCode.isNotEmpty && memberCodeCode.isNotEmpty
        ? '$unitCode-$memberCodeCode'
        : (unitCode.isNotEmpty ? unitCode : memberCodeCode);

    return AttendanceEntry(
      memberName: json['memberName'] ?? '',
      code: combinedCode.isNotEmpty ? combinedCode : null,
      inTime: json['intime'],
      outTime: json['outTime'],
    );
  }

  AttendanceEntry copyWith({
    String? memberName,
    String? code,
    String? inTime,
    String? outTime,
  }) {
    return AttendanceEntry(
      memberName: memberName ?? this.memberName,
      code: code ?? this.code,
      inTime: inTime ?? this.inTime,
      outTime: outTime ?? this.outTime,
    );
  }
}
