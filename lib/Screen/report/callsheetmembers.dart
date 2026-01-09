import 'dart:convert';
import 'package:cinefo_dubbing/ApiCalls/apicall.dart';
import 'package:cinefo_dubbing/sessionexpired.dart';
import 'package:cinefo_dubbing/variables.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;


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
    print(widget.maincallsheetid);
    print(dubbingunitid);
    print(globalloginData?['vsid'] ?? '');
    
//api call
    try {
      
      final result = await attendencereportapi(
        callsheetid: widget.maincallsheetid,
      );
      
      if (result['success'] == true && result['statusCode'] == 200) {
        print("${result['body']}✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ");
        final decoded = jsonDecode(result['body']);

        // Check if there's a message to show
        if (decoded['message'] != null &&
            decoded['message'].toString().isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(decoded['message'].toString()),
              backgroundColor: decoded['responseData'] != null
                  ? Colors.green
                  : Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }

        if (decoded['responseData'] != null) {
          List<AttendanceEntry> entries = (decoded['responseData'] as List)
              .map((e) => AttendanceEntry.fromJson(e))
              .toList();
          setState(() {
            reportData = entries;
            isLoading = false;
          });
        } else {
          // No data found, stop loading
          setState(() {
            reportData = [];
            isLoading = false;
          });
        }
      } else {
        Map error = jsonDecode(result['body']);
        print(error);
        if (error['errordescription'] == "Session Expired") {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const Sessionexpired()));
        }
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Exception: $e");
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
              SizedBox(height: 20),
              Container(
                width: MediaQuery.of(context).size.width,
                height: 80,
                color: Colors.white,
                child: Padding(
                  padding: EdgeInsets.only(left: 30, top: 20),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.arrow_back),
                      ),
                      SizedBox(width: 20),
                      Text(
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
                padding: EdgeInsets.only(left: 20, right: 20, top: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(228, 215, 248, 1),
                        border: Border.all(
                          color: Color.fromRGBO(131, 77, 218, 1),
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: Text('Code',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromRGBO(131, 77, 218, 1),
                                )),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text('Name',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromRGBO(131, 77, 218, 1),
                                )),
                          ),
                          Expanded(
                            child: Text('In Time',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromRGBO(131, 77, 218, 1),
                                )),
                          ),
                          SizedBox(width: 20),
                          Expanded(
                            child: Text('Out Time',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromRGBO(131, 77, 218, 1),
                                )),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: isLoading
                    ? Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        itemCount: reportData.length,
                        itemBuilder: (context, index) {
                          final entry = reportData[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              children: [
                                Expanded(
                                    flex: 2, child: Text(entry.code ?? "--")),
                                Expanded(
                                    flex: 3, child: Text(entry.memberName)),
                                Expanded(child: Text(entry.inTime ?? "--")),
                                SizedBox(width: 20),
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
