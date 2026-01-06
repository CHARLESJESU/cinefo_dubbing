import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';
import '../variables.dart';
import '../sessionexpired.dart';

// Helper to check for session expiration and navigate if needed
void _checkSessionExpiration(String responseBody) {
  try {
    final decoded = jsonDecode(responseBody);
    if (decoded is Map && decoded['errordescription'] == "Session Expired") {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (context) => const Sessionexpired()),
      );
    }
  } catch (e) {
    // If JSON parsing fails, ignore
  }
}

// Helper to show concise user-facing SnackBars from non-UI code.
// Do NOT show exception details to the user. Network errors display
// a red "Network issue" message; all other errors show a generic
// message without exposing exception text.
void _showExceptionSnackBar(Object e, {String? prefix, int maxLength = 120}) {
  final bool isNetworkError = e is SocketException;

  if (isNetworkError) {
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text('Network issue'), backgroundColor: Colors.red),
    );
    return;
  }

  // Generic message for non-network errors; do not include exception details.
  scaffoldMessengerKey.currentState?.showSnackBar(
    SnackBar(
      content: Text('Something went wrong'),
      backgroundColor: Colors.orange,
    ),
  );
}

Future<void> fetchloginDataFromSqlite() async {
  try {
    final dbPath = path.join(await getDatabasesPath(), 'production_login.db');
    final Database db = await openDatabase(dbPath);

    final List<Map<String, dynamic>> rows = await db.query(
      'login_data',
      orderBy: 'id ASC',
      limit: 1,
    );
    if (rows.isNotEmpty) {
      final Map<String, dynamic> first = rows.first;

      globalloginData = first;
      productionTypeId = first['production_type_id'] ?? 0;
      vmid = first['vmid'];
      vuid = first['vuid'];
      vpid = first['vpid'];
      unitid = first['unitid'];
      projectId = first['project_id']?.toString() ?? "0";
      vsid = first['vsid'];
      mtypeId = first['mtypeId'];
      vmTypeId = first['vmTypeId'];
      vbpid = first['vbpid'];
      vpoid = first['vpoid'];

      print(
        "📊 SQLite Load - VMID: $vmid, ProjectID: $projectId, UnitID: $unitid, VUID: $vuid, VSID: $vsid",
      );
    }
  } on SocketException catch (e) {
    print('❌ SocketException fetching login data: $e');
    _showExceptionSnackBar(e, prefix: 'Turn on the network');
  } catch (e) {
    print('❌ Error fetching login data from SQLite: $e');
    _showExceptionSnackBar(e);
  }
}

// Direct API to create a callsheet
Future<Map<String, dynamic>> createCallSheetApi({
  required String callsheetname,
  required int shiftId,
  required double latitude,
  required double longitude,
  required String location,
  required String locationType,
  required int locationTypeId,
  required String createdAt,
  required String createdDate,
  required String createdAtTime,
}) async {
  try {
    if (globalloginData == null) await fetchloginDataFromSqlite();

    final payload = {
      "name": callsheetname,
      "shiftId": shiftId,
      "latitude": latitude,
      "longitude": longitude,
      "projectId": globalloginData?['project_id'] ?? '',
      "vmid": globalloginData?['vmid'] ?? '',
      "vpid": globalloginData?['vpid'] ?? '',
      "vpoid": globalloginData?['vpoid'] ?? '',
      "vbpid": globalloginData?['vbpid'] ?? '',
      "productionTypeid": globalloginData?['production_type_id'] ?? '',
      "location": location,
      "locationType": "In-station",
      "locationTypeId": 1,
      "date": createdDate,
      "createdDate": createdDate,
      "createdTime": createdAtTime,
    };

    print("🚀 Creating CallSheet directly with payload: $payload");

    final createcallsheetresponse = await http.post(
      processSessionRequest,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'VMETID':
            'U2DhAAJYK/dbno+9M7YQDA/pzwEzOu43/EiwXnpz9lfxZA32d6CyxoYt1OfWxfE1oAquMJjvptk3K/Uw1/9mSknCQ2OVkG+kIptUboOqaxSqSXbi7MYsuyUkrnedc4ftw0SORisKVW5i/w1q0Lbafn+KuOMEvxzLXjhK7Oib+n4wyZM7VhIVYcODI3GZyxHmxsstQiQk9agviX9U++t4ZD4C7MbuIJtWCYuClDarLhjAXx3Ulr/ItA3RgyIUD6l3kjpsHxWLqO3kkZCCPP8N5+7SoFw4hfJIftD7tRUamgNZQwPzkq60YRIzrs1BlAQEBz4ofX1Uv2ky8t5XQLlEJw==',
        'VSID': globalloginData?['vsid'] ?? '',
      },
      body: jsonEncode(payload),
    );

    print('🚀 createCallSheetApi Response: ${createcallsheetresponse.body}');

    _checkSessionExpiration(createcallsheetresponse.body);

    return {
      'statusCode': createcallsheetresponse.statusCode,
      'body': createcallsheetresponse.body,
      'success': createcallsheetresponse.statusCode == 200,
      'data': jsonDecode(createcallsheetresponse.body),
    };
  } catch (e) {
    _showExceptionSnackBar(
      e,
      prefix: e is SocketException ? 'Turn on the network' : null,
    );
    print('❌ Error in createCallSheetApi: $e');
    return {
      'statusCode': 0,
      'body': '',
      'success': false,
      'errorMessage': e is SocketException
          ? 'Network issue'
          : 'Something went wrong',
    };
  }
}

Future<Map<String, dynamic>> agentreportapi() async {
  try {
    final payload = {};
    print("agentreportapiagentreportapi ${globalloginData?['vsid']}");
    final tripstatusresponse = await http.post(
      processSessionRequest,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'VMETID':
            'Oi05x+2wDhjG1diiQLR9DV6UwTPSDdKGvjNubE+YYu/ZpQ28r5o6d3NMOcFfbkIRpQ1Wk667jx5ksuyGpm3mE3vD1KOeoxTmu4c9ZFwXst8MSA1E+3kkvc9DgEGDXCou+gB64ztDzmo46NIPGVWl+nFdCyBxDnWn0sVaDWV2EIZh9ZADizVNOGfK5WVxWPZPipiBlQ9Pc9rzTo+JqvHmY7G0MXvnVQpnIMoIov5Hr7gP02/NhijxTA7+yLEggkZ0Ko+FogRjSi32PwnzY/K/dPntPT4cdXXuQIOV2CPePsd4Hy+pjrx79v2wD1V37zb8uDx+7kQ2QtWhvtK7R6iwEw==',
        'VSID': globalloginData?['vsid'] ?? '',
      },
      body: jsonEncode(payload),
    );

    print(
        '🚗 driverreportapi Status API Response Status: ${tripstatusresponse.statusCode}');
    print('🚗 driverreportapi Status API Response Status: ${payload}');
    print(
        '🚗 driverreportapi Status API Response Body: ${tripstatusresponse.body}');

    return {
      'statusCode': tripstatusresponse.statusCode,
      'body': tripstatusresponse.body,
      'success': tripstatusresponse.statusCode == 200,
    };
  } catch (e) {
    print('❌ Error in tripstatusapi: $e');
    return {
      'statusCode': 0,
      'body': 'Error: $e',
      'success': false,
    };
  }
}


Future<Map<String, dynamic>> attendencereportapi({
  required String callsheetid,
}) async {
  try {
    if (globalloginData == null) await fetchloginDataFromSqlite();

    final payload = {
      "unitid": dubbingunitid,
      "callsheetid": callsheetid,
      "vmid": 0,
    };
    final tripstatusresponse = await http.post(
      processSessionRequest,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'VMETID':
            'VtHdAOR3ljcro4U+M9+kByyNPjr8d/b3VNhQmK9lwHYmkC5cUmqkmv6Ku5FFOHTYi9W80fZoAGhzNSB9L/7VCTAfg9S2RhDOMd5J+wkFquTCikvz38ZUWaUe6nXew/NSdV9K58wL5gDAd/7W0zSOpw7Qb+fALxSDZ8UmWdk7MxLkZDn0VIHwVAgv13JeeZVivtG7gu0DJvTyPixMJUFCQzzADzJHoIYtgXV4342izgfc4Lqca4rdjVwYV79/LLqmz1M8yAWXqfSRb+ArLo6xtPrjPInGZcIO8U6uTH1WmXvw+pk3xKD/WEEAFk69w8MI1TrntrzGgDPZ21NhqZXE/w==',
        'VSID': globalloginData?['vsid'] ??  '',
      },
      body: jsonEncode(payload),
    );

    print(
      '🚗 attendencereportapi Status API Response Status: ${tripstatusresponse.statusCode}',
    );
    print('🚗 attendencereportapi Payload: ${payload}');
    print(
      '🚗 attendencereportapi Status API Response Body: ${tripstatusresponse.body}',
    );

    _checkSessionExpiration(tripstatusresponse.body);

    return {
      'statusCode': tripstatusresponse.statusCode,
      'body': tripstatusresponse.body,
      'success': tripstatusresponse.statusCode == 200,
    };
  } catch (e) {
    _showExceptionSnackBar(
      e,
      prefix: e is SocketException ? 'Turn on the network' : null,
    );
    print('❌ Error in attendencereportapi: $e');
    return {
      'statusCode': 0,
      'body': '',
      'success': false,
      'errorMessage': e is SocketException
          ? 'Network issue'
          : 'Something went wrong',
    };
  }
}

Future<Map<String, dynamic>> fetchcallsheetapi({required int projectid}) async {
  try {
    if (globalloginData == null) await fetchloginDataFromSqlite();

    final payload = {
      "projectid": globalloginData?['project_id'] ?? '',
      "statusid": 1,
    };
    final fetchcallsheetapiresponse = await http.post(
      processSessionRequest,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'VMETID':
            'RxvjE+jpr7/hdMwDmyDIz5+FC3qCCTJfmFVMypvuabzCRU/uge/pTo80n0qeb1J+XPjQ/JulyZ/5ufuiPOEQ9xm84PHIeHYz3dXvNCuuyFYO1Vfpq4B79KHm5kEbv5M3YvEn7YSUoetwT0mnNMUJUB1zwDNoOxCk7MQ7+71CXlphHDn/O5Nx1klD0Pc/LlDdZmwV2WcKWRvNgvlllG3eAVuVO8A4ng0mR14Rr/lfJfK0wxH7xu/9UShGk5529kKcRYtndqTr4CgCozRTInR1cIUbkKoeCCbdykcuVmEY8h23UatlRLGUsD9FJXRioRmOo9hKOgtk9FxC1qoJhV+x+g==',
        'VSID': globalloginData?['vsid'] ??  '',
      },
      body: jsonEncode(payload),
    );

    print(
      '🚗 fetchcallsheetapi Status API Response Status: ${fetchcallsheetapiresponse.statusCode}',
    );
    print('🚗 fetchcallsheetapi Payload: ${payload}');
    print(
      '🚗 fetchcallsheetapi Status API Response Body: ${fetchcallsheetapiresponse.body}',
    );

    _checkSessionExpiration(fetchcallsheetapiresponse.body);

    return {
      'statusCode': fetchcallsheetapiresponse.statusCode,
      'body': fetchcallsheetapiresponse.body,
      'success': fetchcallsheetapiresponse.statusCode == 200,
    };
  } catch (e) {
    _showExceptionSnackBar(
      e,
      prefix: e is SocketException ? 'Turn on the network' : null,
    );
    print('❌ Error in fetchcallsheetapi: $e');
    return {
      'statusCode': 0,
      'body': '',
      'success': false,
      'errorMessage': e is SocketException
          ? 'Network issue'
          : 'Something went wrong',
    };
  }
}

Future<Map<String, dynamic>> forouttimelookupapi() async {
  try {
    if (globalloginData == null) await fetchloginDataFromSqlite();

    final payload = {};
    final forouttimelookupapiresponse = await http.post(
      processSessionRequest,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'VMETID':
            'Bz0Pmf2BnX5zgYLKjoR+OJrgsp8ONRRtexO8AoYyhCYUuJUjCI2wlElILwRm0CQE8Cn2XJkvRY1FT+xuXUYUwqWYSxc40wzbecpGud3i2O4zsN1bX1FAjHWR2JgSyUXEAhjpyrtln15IkXD62j9GgqrJlR4yfFWLv14HkX+L0dMxF67Mm13f6cUQXYaQS8AJs+H2BqVwjnGqVvVaJ8tGor8cadKoDqiwst9C8g2KshLLlPLdyuKirErLThbp+qZ5nQgPJeMtvjuqU9m2p6RmsxuAZgH4+R5Z4jA2OZjlnOO/1hs4K9KWOzMovGiGLuXKfXZbII7wQdX7kItn8uepCQ==',
        'VSID': globalloginData?['vsid'] ?? '',
      },
      body: jsonEncode(payload),
    );

    print(
      '🚗 fetchcallsheetapi Status API Response Status: ${forouttimelookupapiresponse.statusCode}',
    );
    print('🚗 fetchcallsheetapi Payload: ${payload}');
    print(
      '🚗 fetchcallsheetapi Status API Response Body: ${forouttimelookupapiresponse.body}',
    );

    _checkSessionExpiration(forouttimelookupapiresponse.body);

    return {
      'statusCode': forouttimelookupapiresponse.statusCode,
      'body': forouttimelookupapiresponse.body,
      'success': forouttimelookupapiresponse.statusCode == 200,
    };
  } catch (e) {
    _showExceptionSnackBar(
      e,
      prefix: e is SocketException ? 'Turn on the network' : null,
    );
    print('❌ Error in forouttimelookupapi: $e');
    return {
      'statusCode': 0,
      'body': '',
      'success': false,
      'errorMessage': e is SocketException
          ? 'Network issue'
          : 'Something went wrong',
    };
  }
}

Future<Map<String, dynamic>> closecallsheetapi({
  required String tempId,
  required Map<String, dynamic> callsheetData,
}) async {
  try {
    if (globalloginData == null) await fetchloginDataFromSqlite();

    final payload = {
      "callshettId": callsheetid,
      "tempId": "",
      "projectid": projectId,
      "shiftid": callsheetData['shiftId'] ?? callsheetData['shiftid'] ?? 0,
      "callSheetStatusId": 3,
      "callSheetTime":
          callsheetData['pack_up_time'] ??
          DateFormat('HH:mm').format(DateTime.now()),
      "callsheetcloseDate":
          callsheetData['pack_up_date'] ??
          DateFormat('dd-MM-yyyy').format(DateTime.now()),
    };

    final closecallsheetapiresponse = await http.post(
      processSessionRequest,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'VMETID':
            'O/OtGf1bn9oD4GFpjRQ+Dec3uinWC4FwTdbrFCyiQDpN8SPMhon+ZaDHuLsnBHmfqGAjFXy6Gdjt6mQwzwqgfdWu+e+M8qwNk8gX9Ca3JxFQc++CDr8nd1Mrr57aHoLMlXprbFMxNy7ptfNoccm61r/9/lHCANMOt85n05HVfccknlopttLI5WM7DsNVU60/x5qylzlpXL24l8KwEFFPK1ky410+/uI3GkYi0l1u9DektKB/m1CINVbQ1Oob+FOW5lhNsBjqgpM/x1it89d7chbThdP5xlpygZsuG0AW4lakebF3ze497e16600v72fclgAZ3M21C0zUM4w9XIweMg==',
        'VSID': globalloginData?['vsid'] ??  '',
      },
      body: jsonEncode(payload),
    );

    print(
      '🚗 closecallsheetapi Status API Response Status: ${closecallsheetapiresponse.statusCode}',
    );
    print('🚗 closecallsheetapi Payload: ${payload}');
    print(
      '🚗 closecallsheetapi Status API Response Body: ${closecallsheetapiresponse.body}',
    );

    _checkSessionExpiration(closecallsheetapiresponse.body);

    // Try to parse the response body to detect logical success, since
    // some endpoints return HTTP 200 even when the operation failed.
    dynamic decoded;
    try {
      decoded = jsonDecode(closecallsheetapiresponse.body);
    } catch (_) {
      decoded = null;
    }

    bool success = false;
    String? errorCode;
    String? errorDescription;

    if (closecallsheetapiresponse.statusCode == 200) {
      if (decoded is Map) {
        errorCode = decoded['errorCode']?.toString();
        errorDescription = decoded['errordescription']?.toString();
        final responseData = decoded['responseData'];
        final statusField = decoded['status']?.toString()?.toLowerCase();

        if (responseData != null) {
          success = true;
        } else if (statusField == 'success') {
          success = true;
        } else if (errorCode == null || errorCode == '0') {
          success = true;
        } else {
          success = false;
        }
      } else {
        // Non-JSON but HTTP 200 -> assume success
        success = true;
      }
    }

    return {
      'statusCode': closecallsheetapiresponse.statusCode,
      'body': closecallsheetapiresponse.body,
      'success': success,
      'data': decoded,
      'errorCode': errorCode,
      'errorDescription': errorDescription,
    };
  } catch (e) {
    _showExceptionSnackBar(
      e,
      prefix: e is SocketException ? 'Turn on the network' : null,
    );
    print('❌ Error in closecallsheetapi: $e');
    return {
      'statusCode': 0,
      'body': '',
      'success': false,
      'errorMessage': e is SocketException
          ? 'Network issue'
          : 'Something went wrong',
    };
  }
}
Future<Map<String, dynamic>> raiserequestapi(int projectid) async {
  try {
    final payload = {
      "callsheetid": 0,
  "projectid": projectid
};
    print("raiserequestapi ${globalloginData?['vsid']}");
    final raiserequestresponse = await http.post(
      processSessionRequest,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'VMETID':
            'LE/EOR30OyNb4E+Kjz45gOazQ6yGMNGd8evS7UqbbZZ3ECwNSBhBziffuiq4Et9kJAZmOVlCIpsaVLuFLTGzaObCpvyDQNACvFTGv/+T93SLNnPZ91xpMjigvv25FmErk24nSx8Y0L3Xo9wNJVFQn58DDdMPMxMuOdrYhUR/kXAMv09yxapmyaDhzxuNA26lF/1yiyczN/eu8n17qhZ0a6uk9VJzYwwHOJBCHrTsoccP4DQBzmu3NB71KunvzmlqexGgToiRLg47h75DV3WSafVQvk9vLL9G7ZxYiBrJM1hg6fST8NazX40BwrtC6herXnEjQHpHwYOQtH+UMr4J7A==',
        'VSID': globalloginData?['vsid'] ?? '',
      },
      body: jsonEncode(payload),
    );

    print(
        '🚗 raiserequestapi Status API Response Status: ${raiserequestresponse.statusCode}');
    print('🚗 raiserequestapi Status API Response Status: ${payload}');
    print(
        '🚗 raiserequestapi Status API Response Body: ${raiserequestresponse.body}');

    return {
      'statusCode': raiserequestresponse.statusCode,
      'body': raiserequestresponse.body,
      'success': raiserequestresponse.statusCode == 200,
    };
  } catch (e) {
    print('❌ Error in tripstatusapi: $e');
    return {
      'statusCode': 0,
      'body': 'Error: $e',
      'success': false,
    };
  }
}
