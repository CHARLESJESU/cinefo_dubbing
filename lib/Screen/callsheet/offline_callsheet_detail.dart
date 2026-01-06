import 'package:flutter/material.dart';
import '../../Attendance/intime.dart';
import '../../Attendance/nfcnotifier.dart';
import '../../Attendance/outtimecharles.dart';
import '../../colorcode/colorcode.dart';
import '../../variables.dart';
import '../../ApiCalls/apicall.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;

class OfflineCallsheetDetailScreen extends StatelessWidget {
  final Map<String, dynamic> callsheet;
  const OfflineCallsheetDetailScreen({Key? key, required this.callsheet})
    : super(key: key);

  Future<void> _deleteCallsheetFromDB(
    String callSheetNo,
    BuildContext context,
  ) async {
    try {
      String dbPath = path.join(
        await getDatabasesPath(),
        'production_login.db',
      );
      Database db = await openDatabase(dbPath);
      final columns = await db.rawQuery("PRAGMA table_info(callsheetoffline)");
      final hasStatus = columns.any((col) => col['name'] == 'status');
      if (!hasStatus) {
        await db.execute("ALTER TABLE callsheetoffline ADD COLUMN status TEXT");
      }
      final allRows = await db.query('callsheetoffline');
      print('All callSheetNo in callsheetoffline:');
      for (var row in allRows) {
        print(row['callSheetNo']);
      }
      final DateTime now = DateTime.now();
      final String currentDate =
          "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";
      final String currentTime =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

      int result = await db.update(
        'callsheetoffline',
        {
          'status': 'closed',
          'pack_up_date': currentDate,
          'pack_up_time': currentTime,
        },
        where: 'callSheetNo = ?',
        whereArgs: [callSheetNo],
      );
      await db.close();
      if (result > 0) {
        print('✅ Callsheet status set to closed: $callSheetNo');
        Navigator.pop(context, true);
      } else {
        print('⚠️ No callsheet found with ID: $callSheetNo');
      }
    } catch (e) {
      print('❌ Error updating callsheet status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Robust mapping with fallbacks for different possible keys
    final String? rawCallSheetId =
        (callsheet['callSheetId'] ??
                callsheet['callsheetid'] ??
                callsheet['id'] ??
                callsheet['v5'] ??
                callsheet['v1'] ??
                callsheet['callsheetId'])
            ?.toString();
    try {
      callsheetid = rawCallSheetId != null
          ? int.tryParse(rawCallSheetId)
          : null;
    } catch (_) {
      callsheetid = null;
    }

    final String name =
        (callsheet['callsheetname'] ??
                callsheet['projectName'] ??
                callsheet['projectname'] ??
                callsheet['MovieName'] ??
                callsheet['moviename'] ??
                callsheet['v3'])
            ?.toString() ??
        'Unknown';

    // created date can be stored under a few names, possibly with a time part
    String createdAtRaw =
        (callsheet['created_at'] ??
                callsheet['createdAt'] ??
                callsheet['date'] ??
                callsheet['callsheetDate'] ??
                callsheet['callsheetdate'] ??
                callsheet['v11'])
            ?.toString() ??
        '';
    // if contains T (ISO datetime), keep only the date part
    if (createdAtRaw.contains('T')) {
      createdAtRaw = createdAtRaw.split('T').first;
    }
    String createdAtDisplay = createdAtRaw;
    try {
      if (createdAtRaw.isNotEmpty) {
        final parts = createdAtRaw.split('-');
        if (parts.length == 3) {
          createdAtDisplay = "${parts[2]}-${parts[1]}-${parts[0]}";
        }
      }
    } catch (_) {}

    final String? id =
        (callsheet['callSheetNo'] ??
                callsheet['callsheetno'] ??
                callsheet['no'] ??
                callsheet['v4'] ??
                callsheet['v2'] ??
                callsheet['callsheetNo'])
            ?.toString();

    final String? location =
        (callsheet['location'] ??
                callsheet['Location'] ??
                callsheet['venue'] ??
                callsheet['place'])
            ?.toString();

    final String? Moviename =
        (callsheet['MovieName'] ??
                callsheet['moviename'] ??
                callsheet['projectName'] ??
                callsheet['projectname'])
            ?.toString();

    final String? time =
        (callsheet['shift'] ??
                callsheet['shiftName'] ??
                callsheet['shiftname'] ??
                callsheet['v13'])
            ?.toString();

    final DateTime now = DateTime.now();
    DateTime? callsheetDate;
    bool isToday = false;
    bool isPastDate = false;
    bool dateParseError = false;
    try {
      callsheetDate = DateTime.tryParse(createdAtRaw);
    } catch (e) {
      print('Error parsing date: $e');
      dateParseError = true;
    }
    if (callsheetDate != null) {
      final DateTime callsheetDay = DateTime(
        callsheetDate.year,
        callsheetDate.month,
        callsheetDate.day,
      );
      final DateTime today = DateTime(now.year, now.month, now.day);
      isToday = callsheetDay == today;
      isPastDate = callsheetDay.isBefore(today);
      print(
        'Callsheet date: '
        '${callsheetDay.toIso8601String()} | Today: ${today.toIso8601String()} | isToday: $isToday | isPastDate: $isPastDate',
      );
    } else {
      print(
        'Callsheet date missing or invalid, enabling attendance buttons by default.',
      );
    }

    bool enableAttendanceButtons =
        isToday || dateParseError || callsheetDate == null;
    bool enableCloseButton =
        isToday || isPastDate || dateParseError || callsheetDate == null;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Callsheet Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2B5682),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: const Color.fromRGBO(247, 244, 244, 1),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        Moviename ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2B5682),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 70,
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Date",
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  createdAtDisplay,
                                  style: TextStyle(
                                    color: Color(0xFF2B5682),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            height: 70,
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Time",
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  time ?? 'Unknown',
                                  style: TextStyle(
                                    color: Color(0xFF2B5682),
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 70,
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "ID",
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  id != null && name.isNotEmpty
                                      ? "$id-$name"
                                      : 'Unknown',
                                  style: TextStyle(
                                    color: Color(0xFF2B5682),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            height: 100,
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Location",
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Builder(
                                  builder: (context) {
                                    final loc = location ?? 'Unknown';
                                    double fontSize = 12;
                                    if (loc.length > 40) {
                                      fontSize = 9;
                                    }
                                    if (loc.length > 80) {
                                      fontSize = 7;
                                    }
                                    return Text(
                                      loc,
                                      style: TextStyle(
                                        color: Color(0xFF2B5682),
                                        fontSize: fontSize,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 25),
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          GestureDetector(
                            onTap: enableAttendanceButtons
                                ? () {
                                    if (productionTypeId == 3) {
                                      isoffline = true;
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              ChangeNotifierProvider(
                                                create: (_) => NFCNotifier(),
                                                child: const IntimeScreen(),
                                              ),
                                        ),
                                      );
                                    } else if (productionTypeId == 2) {
                                      isoffline = true;
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              ChangeNotifierProvider(
                                                create: (_) => NFCNotifier(),
                                                child: const IntimeScreen(),
                                              ),
                                        ),
                                      );
                                    }
                                  }
                                : null,
                            child: _actionButton(
                              "In-time",
                              Icons.login,
                              enableAttendanceButtons
                                  ? AppColors.primaryLight
                                  : Colors.grey,
                              enabled: enableAttendanceButtons,
                            ),
                          ),
                          GestureDetector(
                            onTap: enableAttendanceButtons
                                ? () {
                                    if (productionTypeId == 3) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              ChangeNotifierProvider(
                                                create: (_) => NFCNotifier(),
                                                child: const Outtimecharles(),
                                              ),
                                        ),
                                      );
                                    } else if (productionTypeId == 2) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              ChangeNotifierProvider(
                                                create: (_) => NFCNotifier(),
                                                child: const Outtimecharles(),
                                              ),
                                        ),
                                      );
                                    }
                                  }
                                : null,
                            child: _actionButton(
                              "Out-time",
                              Icons.logout,
                              enableAttendanceButtons
                                  ? AppColors.primaryLight
                                  : Colors.grey,
                              enabled: enableAttendanceButtons,
                            ),
                          ),
                          if (productionTypeId != 3)
                            GestureDetector(
                              onTap: enableAttendanceButtons
                                  ? () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Configuration screen not available offline',
                                          ),
                                        ),
                                      );
                                    }
                                  : null,
                              child: _actionButton(
                                "Config",
                                Icons.settings,
                                enableAttendanceButtons
                                    ? AppColors.primaryLight
                                    : Colors.grey,
                                enabled: enableAttendanceButtons,
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    Opacity(
                      opacity: enableCloseButton ? 1.0 : 0.5,
                      child: GestureDetector(
                        onTap: enableCloseButton
                            ? () async {
                                if (id != null) {
                                  try {
                                    final resp = await closecallsheetapi(
                                      tempId: id,
                                      callsheetData: callsheet,
                                    );
                                    if (resp['success'] == true) {
                                      Navigator.pop(context);
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Failed to close callsheet online.',
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    print(
                                      'Error calling closecallsheetapi: $e',
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Error closing callsheet.',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              }
                            : null,
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 15),
                          decoration: BoxDecoration(
                            color: enableCloseButton
                                ? Colors.red.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: enableCloseButton
                                  ? Colors.red.withOpacity(0.3)
                                  : Colors.grey.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.close,
                                color: enableCloseButton
                                    ? Colors.red
                                    : Colors.grey,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Pack Up",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: enableCloseButton
                                      ? Colors.red
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButton(
    String title,
    IconData icon,
    Color color, {
    bool enabled = true,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: enabled ? Colors.black87 : Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
