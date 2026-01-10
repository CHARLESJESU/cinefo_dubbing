import 'package:cinefo_dubbing/ApiCalls/apicall.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import 'package:http/http.dart' as http;

import '../variables.dart';
String transformVcidToImageUrl(String vcid) {
  final transformedVcid = vcid
      .replaceAll('/', '_')
      .replaceAll('=', '-')
      .replaceAll('+', '-')
      .replaceAll('#', '-');
  return 'https://vfs.vframework.in/Upload/vcard/Image/$transformedVcid.png';
}

void showResultDialogi(
  BuildContext context,
  String message,
  VoidCallback onDismissed,
  String vcid,
  String rfid,
  String attendanceStatus,
) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return _CountdownDialog(
        message: message,
        onDismissed: onDismissed,
        vcid: vcid,
        rfid: rfid,
        attendanceStatus: attendanceStatus,
      );
    },
  );
}

class _CountdownDialog extends StatefulWidget {
  final String message;
  final VoidCallback onDismissed;
  final String vcid;
  final String rfid;
  final String attendanceStatus;

  const _CountdownDialog({
    Key? key,
    required this.message,
    required this.onDismissed,
    required this.vcid,
    required this.rfid,
    required this.attendanceStatus,
  }) : super(key: key);

  @override
  State<_CountdownDialog> createState() => _CountdownDialogState();
}

class _CountdownDialogState extends State<_CountdownDialog> {
  Future<void> saveIntimeToSQLite(Map<String, dynamic> data) async {
    print('DEBUG: saveIntimeToSQLite started');
    try {
      final dbPath = await getDatabasesPath();
      print('DEBUG: Database path: $dbPath');
      final db = await openDatabase(path.join(dbPath, 'production_login.db'));
      print('DEBUG: Database opened successfully');

      // Drop the old table if it exists to ensure schema is correct
      // await db.execute('DROP TABLE IF EXISTS intime');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS intime (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          designation TEXT,
          rfid TEXT,
          code TEXT,
          unionName TEXT,
          vcid TEXT,
          marked_at TEXT,
          latitude TEXT,
          longitude TEXT,
          location TEXT,
          attendance_status TEXT,
          callsheetid INTEGER,
          mode TEXT,
          attendanceDate TEXT,
          attendanceTime TEXT,
          doubing TEXT
        )
      ''');
      print('DEBUG: Table created/verified successfully');

      await db.insert('intime', data);
      print('DEBUG: Data inserted successfully: $data');

      // IMPORTANT: do NOT close the database here. The app uses a shared
      // SQLite connection in multiple places (for example the background
      // IntimeSyncService). Closing the database here can close the shared
      // connection unexpectedly and cause DatabaseException(error database_closed)
      // elsewhere. Let the caller or the app lifecycle manage closing.
      // await db.close();
      print('DEBUG: Leaving database open (caller/app manages lifecycle)');
    } catch (e) {
      print('ERROR in saveIntimeToSQLite: $e');
      print('ERROR stack trace: ${e.toString()}');
      rethrow;
    }
  }

  String? latitude, longitude, location;
  bool _isloading = false;
  bool _attendanceMarked = false;
  String debugMessage = '';
  Timer? _timer;
  bool first = false;
  String responseMessage = "";
  bool _showRoleSelection = false;
  
  // Map to store checkbox states for role selection
  final Map<String, int> _configMap = {
    "mainCharacter": 0,
    "smallCharacter": 0,
    "bitCharacter": 0,
    "singlebitCharacter": 0,
    "group": 0,
    "fight": 0,
    "singlebitCharacterOtherLanguage": 0,
    "mainCharacterOtherLanguage": 0,
    "smallCharacterOtherLanguage": 0,
    "bitCharacterOtherLanguage": 0,
    "groupOtherLanguage": 0,
    "fightOtherLanguage": 0,
    "voicetest": 0,
    "correction": 0,
    "leadRole": 0,
    "secondLeadRole": 0,
    "leadRoleOtherLanguage": 0,
    "secondLeadRoleOtherLanguage": 0,
  };
  
  final Map<String, String> _labels = {
    "mainCharacter": "Main Character",
    "smallCharacter": "Small Character",
    "bitCharacter": "Bit Character",
    "singlebitCharacter": "Single Bit Character",
    "group": "Group",
    "fight": "Fight",
    "singlebitCharacterOtherLanguage": "Single Bit Character (Other Language)",
    "mainCharacterOtherLanguage": "Main Character (Other Language)",
    "smallCharacterOtherLanguage": "Small Character (Other Language)",
    "bitCharacterOtherLanguage": "Bit Character (Other Language)",
    "groupOtherLanguage": "Group (Other Language)",
    "fightOtherLanguage": "Fight (Other Language)",
    "voicetest": "Voice Test",
    "correction": "Correction",
    "leadRole": "Lead Role",
    "secondLeadRole": "Second Lead Role",
    "leadRoleOtherLanguage": "Lead Role (Other Language)",
    "secondLeadRoleOtherLanguage": "Second Lead Role (Other Language)",
  };
  
  int get _selectedCount => _configMap.values.where((v) => v == 1).length;

  void updateDebugMessage(String msg) {
    if (!mounted) return;
    setState(() {
      debugMessage = msg;
    });
  }

  @override
  void initState() {
    super.initState();
    // _syncOfflineData();
    _getCurrentLocation();
    if (widget.message != "Please Enable NFC From Settings") {
      print('Passing vcid to dialog: ${widget.vcid}');
      markattendance(widget.vcid); // <-- auto mark attendance
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    updateDebugMessage("Checking location service...");

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      updateDebugMessage("Location services are disabled.");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        updateDebugMessage("Location permission denied.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      updateDebugMessage("Location permission permanently denied.");
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      Placemark place = placemarks[0];

      setState(() {
        latitude = position.latitude.toString();
        longitude = position.longitude.toString();
        location =
            "${place.name}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
      });
      updateDebugMessage("Location fetched: $location");
    } catch (e) {
      updateDebugMessage("Error fetching location: $e");
    }
  }

  // --- Background FIFO sync service ---

  Future<bool> checkIfAttendanceAlreadyMarked(String rfid) async {
    try {
      final dbPath = await getDatabasesPath();
      final db = await openDatabase(path.join(dbPath, 'production_login.db'));

      final List<Map<String, dynamic>> existingRecords = await db.query(
        'intime',
        where: 'rfid = ? AND callsheetid = ? AND attendance_status = ?',
        whereArgs: [rfid, callsheetid, widget.attendanceStatus],
      );

      // IMPORTANT: do NOT close the shared DB here for the same reason as above.
      // Closing this connection while other parts of the app (e.g., the sync
      // service) hold a reference can trigger database_closed exceptions.
      // await db.close();
      return existingRecords.isNotEmpty;
    } catch (e) {
      print('ERROR checking existing attendance: $e');
      return false;
    }
  }

  Future<void> markattendance(String vcid) async {
    print('DEBUG: markattendance started with vcid: $vcid');
    setState(() {
      first = true;
    });
    if (_attendanceMarked) {
      print('DEBUG: Attendance already marked, returning');
      return;
    }

    // Check if attendance is already marked for this vcid and callsheet
    bool alreadyMarked = await checkIfAttendanceAlreadyMarked(widget.rfid);
    if (alreadyMarked) {
      print('DEBUG: Attendance already exists for vcid: $vcid');
      setState(() {
        first = false;
        responseMessage = "Attendance already marked";
      });

      // Show dialog and close after delay
      Future.delayed(Duration(milliseconds: 1500), () {
        if (mounted) {
          Navigator.of(context).pop();
          widget.onDismissed();
        }
      });
      return;
    }

    setState(() => _isloading = true);
    _attendanceMarked = true;

    try {
      print('DEBUG: Starting data extraction from message');
      // Extract NFC fields from widget.message
      String name = '', designation = '', code = '', unionName = '';
      final lines = widget.message.split('\n');
      for (final line in lines) {
        if (line.startsWith('Name:'))
          name = line.replaceFirst('Name:', '').trim();
        if (line.startsWith('Designation:'))
          designation = line.replaceFirst('Designation:', '').trim();
        if (line.startsWith('Code:'))
          code = line.replaceFirst('Code:', '').trim();
        if (line.startsWith('Union Name:'))
          unionName = line.replaceFirst('Union Name:', '').trim();
      }
      print(
        'DEBUG: Extracted data - Name: $name, Designation: $designation, Code: $code, Union: $unionName',
      );

      // Get current location if available
      print('DEBUG: Getting location data');
      String? lat = latitude, lon = longitude, loc = location;
      if (lat == null || lon == null || loc == null) {
        print('DEBUG: Location not available, fetching current location');
        try {
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          lat = position.latitude.toString();
          lon = position.longitude.toString();
          List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );
          Placemark place = placemarks[0];
          loc =
              "${place.name}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
          print(
            'DEBUG: Location fetched - Lat: $lat, Lon: $lon, Location: $loc',
          );
        } catch (e) {
          print('DEBUG: Error fetching location: $e');
          lat = '';
          lon = '';
          loc = '';
        }
      } else {
        print(
          'DEBUG: Using cached location - Lat: $lat, Lon: $lon, Location: $loc',
        );
      }

      print('DEBUG: Creating intime data object');
      
      // Get doubing config - if attendanceStatus is '2', show role selection UI inline
      if (widget.attendanceStatus == '2') {
        print('DEBUG: Attendance status is 2, showing role selection UI');
        setState(() {
          _showRoleSelection = true;
          _isloading = false;
        });
        return; // Wait for user to select roles
      }
      
      // Continue with attendance saving (called after role selection or directly if status != '2')
      await _saveAttendanceData(name, designation, code, unionName, vcid, lat!, lon!, loc!, null);
    } catch (e) {
      print('ERROR in markattendance: $e');
      print('ERROR stack trace: ${e.toString()}');
    } finally {
      if (!mounted) return;
      setState(() => _isloading = false);
      print('DEBUG: markattendance completed');
    }
  }
  
  Future<void> _saveAttendanceData(
    String name,
    String designation,
    String code,
    String unionName,
    String vcid,
    String lat,
    String lon,
    String loc,
    Map<String, int>? selectedConfigMap,
  ) async {
    try {
      Map<String, dynamic> intimeData = {
        'name': name,
        'designation': designation,
        'rfid': widget.rfid,
        'code': code,
        'unionName': unionName,
        'vcid': vcid,
        'marked_at': DateTime.now().toIso8601String(),
        'latitude': lat,
        'longitude': lon,
        'location': loc,
        'attendance_status': widget.attendanceStatus,
        'callsheetid': callsheetid,
        'mode': isoffline ? 'offline' : 'online',
        'attendanceDate':
            "${DateTime.now().day.toString().padLeft(2, '0')}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().year}",
        'attendanceTime': DateTime.now().toString().split(' ')[1].split('.')[0],
        'doubing': selectedConfigMap != null
            ? jsonEncode(selectedConfigMap)
            : jsonEncode({
                "mainCharacter": 0,
                "smallCharacter": 0,
                "bitCharacter": 0,
                "singlebitCharacter": 0,
                "group": 0,
                "fight": 0,
                "singlebitCharacterOtherLanguage": 0,
                "mainCharacterOtherLanguage": 0,
                "smallCharacterOtherLanguage": 0,
                "bitCharacterOtherLanguage": 0,
                "groupOtherLanguage": 0,
                "fightOtherLanguage": 0,
                "voicetest": 0,
                "correction": 0,
                "leadRole": 0,
                "secondLeadRole": 0,
                "leadRoleOtherLanguage": 0,
                "secondLeadRoleOtherLanguage": 0,
              }),
      };
      print('DEBUG: Intime data created: $intimeData');

      print('DEBUG: Saving to SQLite');
      await saveIntimeToSQLite(intimeData);
      print('DEBUG: SQLite save completed');

      if (!mounted) {
        print('DEBUG: Widget not mounted, returning');
        return;
      }

      print('DEBUG: Setting response message');
      setState(() {
        first = false;
        responseMessage = "Attendance stored locally.";
      });
      print('DEBUG: Response message set, scheduling dialog close');

      // Close dialog immediately after showing success message
      Future.delayed(Duration(milliseconds: 800), () {
        print('DEBUG: Closing dialog');
        if (mounted) {
          // For attendance_status '2', pop twice; for '1', pop once
          if (widget.attendanceStatus == '2') {
            Navigator.of(context).pop(); // First pop
            Navigator.of(context).pop(); // Second pop
          } else {
            Navigator.of(context).pop(); // Single pop for status '1'
          }
          widget.onDismissed();
        }
      });
    } catch (e) {
      print('ERROR in _saveAttendanceData: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = transformVcidToImageUrl(widget.vcid);
    final isNfcDisabled = widget.message == "Please Enable NFC From Settings";
    final isAlreadyMarked = responseMessage == "Attendance already marked";

    // Show role selection UI
    if (_showRoleSelection) {
      final keys = _configMap.keys.toList();
      return AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.people_alt, color: Colors.white),
                    const SizedBox(width: 12),
                    const Text(
                      'Select Role',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: keys.length,
                  itemBuilder: (context, index) {
                    final key = keys[index];
                    final label = _labels[key] ?? key;
                    final checked = _configMap[key] == 1;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: checked ? Colors.blue.shade50 : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: checked ? Colors.blue.shade300 : Colors.grey.shade300,
                          width: checked ? 2 : 1,
                        ),
                      ),
                      child: CheckboxListTile(
                        title: Text(
                          label,
                          style: TextStyle(
                            fontWeight: checked ? FontWeight.w600 : FontWeight.w500,
                            color: checked ? Colors.blue.shade900 : Colors.grey[800],
                            fontSize: 14,
                          ),
                        ),
                        value: checked,
                        activeColor: Colors.blue.shade700,
                        checkColor: Colors.white,
                        dense: true,
                        onChanged: (v) {
                          setState(() {
                            _configMap[key] = (v == true) ? 1 : 0;
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _showRoleSelection = false;
                            _isloading = false;
                            responseMessage = "Attendance cancelled";
                          });
                          Future.delayed(Duration(milliseconds: 800), () {
                            if (mounted) {
                              Navigator.of(context).pop();
                              widget.onDismissed();
                            }
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                          side: BorderSide(color: Colors.grey.shade400),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _selectedCount == 0 ? null : () async {
                          setState(() => _isloading = true);
                          // Extract data from widget.message
                          String name = '', designation = '', code = '', unionName = '';
                          final lines = widget.message.split('\n');
                          for (final line in lines) {
                            if (line.startsWith('Name:'))
                              name = line.replaceFirst('Name:', '').trim();
                            if (line.startsWith('Designation:'))
                              designation = line.replaceFirst('Designation:', '').trim();
                            if (line.startsWith('Code:'))
                              code = line.replaceFirst('Code:', '').trim();
                            if (line.startsWith('Union Name:'))
                              unionName = line.replaceFirst('Union Name:', '').trim();
                          }
                          
                          String lat = latitude ?? '', lon = longitude ?? '', loc = location ?? '';
                          if (lat.isEmpty || lon.isEmpty || loc.isEmpty) {
                            try {
                              Position position = await Geolocator.getCurrentPosition(
                                desiredAccuracy: LocationAccuracy.high,
                              );
                              lat = position.latitude.toString();
                              lon = position.longitude.toString();
                              List<Placemark> placemarks = await placemarkFromCoordinates(
                                position.latitude,
                                position.longitude,
                              );
                              Placemark place = placemarks[0];
                              loc = "${place.name}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
                            } catch (e) {
                              lat = '';
                              lon = '';
                              loc = '';
                            }
                          }
                          
                          setState(() => _showRoleSelection = false);
                          await _saveAttendanceData(
                            name,
                            designation,
                            code,
                            unionName,
                            widget.vcid,
                            lat,
                            lon,
                            loc,
                            _configMap,
                          );
                          setState(() => _isloading = false);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade400,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'Submit ($_selectedCount)',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show normal attendance dialog
    return AlertDialog(
      contentPadding: const EdgeInsets.all(16.0),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isNfcDisabled)
            ClipOval(
              child: widget.vcid.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.grey,
                        );
                      },
                    )
                  : const Icon(Icons.person, size: 60, color: Colors.grey),
            ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isAlreadyMarked)
                Icon(Icons.warning, color: Colors.orange, size: 20),
              if (isAlreadyMarked) const SizedBox(width: 8),
              Flexible(
                child: Text(
                  responseMessage.isNotEmpty ? responseMessage : widget.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isAlreadyMarked ? Colors.orange : Colors.black,
                    fontWeight: isAlreadyMarked
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_isloading) const CircularProgressIndicator(color: Colors.black),
        ],
      ),
    );
  }
}

// 📊 📊 📊 📊 📊 📊 📊 📊 📊 📊 📊 📊 📊 📊 📊 📊 📊 📊 📊 📊 📊 📊 📊 📊 📊 📊 📊 📊 📊 📊 📊
// In this code block, we define the IntimeSyncService class
class IntimeSyncService {
  Timer? _timer;
  bool _isPosting = false;

  void startSync() {
    print('IntimeSyncService: startSync() called. Timer started.');
    _timer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _tryPostIntimeRows(),
    );
  }

  void stopSync() {
    _timer?.cancel();
  }

  Future<void> _tryPostIntimeRows() async {
    // await processAllOfflineCallSheets();
    print('IntimeSyncService: Timer fired, checking for rows...');
    if (_isPosting) return;
    _isPosting = true;
    Database? db;
    try {
      var connectivityResult = await Connectivity().checkConnectivity();
      print('IntimeSyncService: Connectivity: $connectivityResult');
      if (connectivityResult == ConnectivityResult.none) {
        print('IntimeSyncService: No internet, skipping this cycle.');
        _isPosting = false;
        return;
      }
      final dbPath = await getDatabasesPath();
      db = await openDatabase(path.join(dbPath, 'production_login.db'));
      await db.execute('''
        CREATE TABLE IF NOT EXISTS intime (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          designation TEXT,
          rfid TEXT,
          code TEXT,
          unionName TEXT,
          vcid TEXT,
          marked_at TEXT,
          latitude TEXT,
          longitude TEXT,
          location TEXT,
          attendance_status TEXT,
          callsheetid INTEGER,
          mode TEXT,
          attendanceDate TEXT,
          attendanceTime TEXT,
          doubing TEXT
        )
      ''');

      final List<Map<String, dynamic>> rows = await db.query(
        'intime',
        where: 'mode = ?',
        whereArgs: ['offline'],
        orderBy: 'id ASC', // FIFO
      );
      await fetchloginDataFromSqlite();
      print('IntimeSyncService: Found \\${rows.length} online rows to sync.');
      for (final row in rows) {
        print('IntimeSyncService: Attempting to POST row id=\\${row['id']}');
        final requestBody = jsonEncode({
          "data": row['vcid'],
          "callsheetid": row['callsheetid'],
          "projectid": projectId,
          "productionTypeId": productionTypeId,
          "rfid": row['rfid'],
          "doubing": row['doubing'] != null 
              ? jsonDecode(row['doubing']) 
              : {},
          "latitude": row['latitude'],
          "longitude": row['longitude'],
          "attendanceStatus": row['attendance_status'],
          "location": row['location'],
          "attendanceDate": row['attendanceDate'],
          "attendanceTime": row['attendanceTime'],
        });
        // Get VSID from loginresponsebody or fallback to SQLite
        String? vsid = loginresponsebody?['vsid']?.toString();
        if (vsid == null || vsid.isEmpty) {
          try {
            final dbPath = await getDatabasesPath();
            final db = await openDatabase(
              path.join(dbPath, 'production_login.db'),
            );
            final List<Map<String, dynamic>> loginRows = await db.query(
              'login_data',
              orderBy: 'id ASC',
              limit: 1,
            );
            if (loginRows.isNotEmpty && loginRows.first['vsid'] != null) {
              vsid = loginRows.first['vsid'].toString();
            }
            await db.close();
          } catch (e) {
            print('Error fetching vsid from SQLite: $e');
          }
        }
        print("Request body : $requestBody");
        print("📊📊📊📊📊📊📊📊📊📊 VSID: $vsid");
        print("📊📊📊📊📊📊📊📊📊📊 Request Body: $processSessionRequest");
        final response = await http.post(
          processSessionRequest,
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'VMETID':
                "ZRaYT9Da/Sv4QuuHfhiVvjCkg5cM5eCUEIN/w8pmJuIB0U/tbjZYxO4ShGIQEr4e5w2lwTSWArgTUc1AcaU/Qi9CxL6bi18tfj5+SWs+Sc9TV/1EMOoJJ2wxvTyRIl7+F5Tz7ELXkSdETOQCcZNaGTYKy/FGJRYVs3pMrLlUV59gCnYOiQEzKObo8Iz0sYajyJld+/ZXeT2dPStZbTR4N6M1qbWvS478EsPahC7vnrS0ZV5gEz8CYkFS959F2IpSTmEF9N/OTneYOETkyFl1BJhWJOknYZTlwL7Hrrl9HYO12FlDRgNUuWCJCepFG+Rmy8VMZTZ0OBNpewjhDjJAuQ==",
            'VSID': vsid ?? "",
          },
          body: requestBody,
        );
            checkSessionExpiration(response.body);
        print(
          'IntimeSyncService: Sending POST request with body: $requestBody',
        );
        // Print response body in chunks to handle large responses
        print('📊 Response body length: ${response.body.length}');
        if (response.body.isNotEmpty) {
          const int chunkSize = 800; // Print in chunks of 800 characters
          for (int i = 0; i < response.body.length; i += chunkSize) {
            int end = (i + chunkSize < response.body.length)
                ? i + chunkSize
                : response.body.length;
            print(
              '📊 Chunk ${(i / chunkSize).floor() + 1}: ${response.body.substring(i, end)}',
            );
          }
        } else {
          print('📊 Response body is empty');
        }

        print('IntimeSyncService: POST statusCode=\\${response.statusCode}');
        if (response.statusCode == 200 
           ) {
          print(
            "IntimeSyncService: Deleting row id=${row['id']} after successful POST.",
          );
          try {
          
            if (db == null || !db.isOpen) {
              print('IntimeSyncService: DB closed, reopening before delete');
              db = await openDatabase(path.join(dbPath, 'production_login.db'));
            }

            await db.delete('intime', where: 'id = ?', whereArgs: [row['id']]);
            print('✅ Successfully deleted row id=${row['id']}');
          } catch (e) {
            print('❌ Error deleting record: $e');
            // Retry once if database was closed unexpectedly
            if (e.toString().contains('database_closed')) {
              try {
                print(
                  'IntimeSyncService: Retry delete - reopening DB and retrying',
                );
                final Database reopenedDb = await openDatabase(
                  path.join(dbPath, 'production_login.db'),
                );
                await reopenedDb.delete(
                  'intime',
                  where: 'id = ?',
                  whereArgs: [row['id']],
                );
                print(
                  '✅ Successfully deleted row id=${row['id']} after reopening DB',
                );
                // make sure the local db reference points to this reopened instance so finally will close it
                db = reopenedDb;
              } catch (e2) {
                print('❌ Retry delete failed: $e2');
              }
            }
          }
        } else if (
            response.statusCode == 404 ||
            response.statusCode == 502) {
          print(
            "IntimeSyncService: Skipping row id=${row['id']} due to statusCode=${response.statusCode}. Data not deleted.",
          );
          // Skip this row, do not delete, continue to next row
          continue;
        } else {
          print(
            "IntimeSyncService: POST failed for row id=${row['id']}, stopping sync this cycle.",
          );
          // Stop on first failure to preserve FIFO
          break;
        }
      }
    } catch (e) {
      print('Sync error: $e');
    } finally {
      if (db != null && db.isOpen) {
        await db.close();
      }
      _isPosting = false;
    }
  }
}