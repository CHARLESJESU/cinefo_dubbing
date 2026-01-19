import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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

/// API Service for Login-related HTTP calls
class LoginApiService {

  static Future<Map<String, dynamic>> fetchBaseUrl(String baseUrl) async {
    try {
      print('🌐 Fetching base URL...');

      final response = await http.post(
        processRequest,
        headers: <String, String>{
          'VMETID':
              'byrZ4bZrKm09R4O7WH6SPd7tvAtGnK1/plycMSP8sD5TKI/VZR0tHBKyO/ogYUIf4Qk6HJXvgyGzg58v0xmlMoRJABt3qUUWGtnJj/EKBsrOaFFGZ6xAbf6k6/ktf2gKsruyfbF2/D7r1CFZgUlmTmubGS1oMZZTSU433swBQbwLnPSreMNi8lIcHJKR2WepQnzNkwPPXxA4/XuZ7CZqqsfO6tmjnH47GoHr7H+FC8GK24zU3AwGIpX+Yg/efeibwapkP6mAya+5BTUGtNtltGOm0q7+2EJAfNcrSTdmoDB8xBerLaNNHhwVHowNIu+8JZl2QM0F/gmVpB55cB8rqg==',
        },
        body: jsonEncode(<String, String>{"baseURL": baseUrl}),
      );

      print('🌐 Base URL API Status: ${response.statusCode}');

      // Print response body in chunks to avoid truncation
      final responseBody = response.body;
      print("🌐 Base URL response length: ${responseBody.length}");
      const chunkSize = 800;
      for (int i = 0; i < responseBody.length; i += chunkSize) {
        final end = (i + chunkSize < responseBody.length)
            ? i + chunkSize
            : responseBody.length;
        final chunk = responseBody.substring(i, end);
        print("🌐 Base URL response chunk ${(i ~/ chunkSize) + 1}: $chunk");
      }
      baseurlresult = jsonDecode(responseBody)['result'];
        print(baseurlresult);
        vpid = baseurlresult?['vpid'] ?? 0;
        vpoid = baseurlresult?['vpoid'] ?? 0;
        ssoGroupId = baseurlresult?['ssoGroupId'] ?? 0;
        vptemplateID = baseurlresult?['vptemplteID'] ?? 0;
      return {
        'statusCode': response.statusCode,
        'body': response.body,
        'success': response.statusCode == 200,
      };
    } catch (e) {
      print('❌ Error in fetchBaseUrl: $e');
      return {
        'statusCode': 0,
        'body': '',
        'success': false,
        'errorMessage': e is SocketException ? 'Network issue' : '',
      };
    }
  }

  /// Login API call
  /// Authenticates user with mobile number and password
  static Future<Map<String, dynamic>> loginUser({
    required String mobileNumber,
    required String password,
    required String vpid,
    required String vptemplateId,
    required String baseUrl,
  }) async {
    try {
      print('🔐 Attempting login for mobile: $mobileNumber');

      final response = await http.post(
        processRequest,
        headers: <String, String>{
          'DEVICETYPE': '2',
          'Content-Type': 'application/json; charset=UTF-8',
          'VPID': vpid,
          'BASEURL': baseUrl,
          'VPTEMPLATEID': vptemplateId,
          'VMETID':
              'jcd3r0UZg4FnqnFKCfAZqwj+d5Y7TJhxN6vIvKsoJIT++90iKP3dELmti79Q+W7aVywvVbhfoF5bdW32p33PbRRTT27Jt3pahRrFzUe5s0jQBoeE0jOraLITDQ6RBv0QoscoOGxL7n0gEWtLE15Bl/HSF2kG5pQYft+ZyF4DNsLf7tGXTz+w/30bv6vMTGmwUIDWqbEet/+5AAjgxEMT/G4kiZifX0eEb3gMxycdMchucGbMkhzK+4bvZKmIjX+z6uz7xqb1SMgPnjKmoqCk8w833K9le4LQ3KSYkcVhyX9B0Q3dDc16JDtpEPTz6b8rTwY8puqlzfuceh5mWogYuA==',
        },
        body: jsonEncode(<String, dynamic>{
          "mobileNumber": mobileNumber,
          "password": password,
        }),
      );

      print('🔐 Login API Status: ${response.statusCode}');

      // Print response body in chunks to avoid truncation
      final responseBody = response.body;
      print("🔐 Login response length: ${responseBody.length}");
      const chunkSize = 800;
      for (int i = 0; i < responseBody.length; i += chunkSize) {
        final end = (i + chunkSize < responseBody.length)
            ? i + chunkSize
            : responseBody.length;
        final chunk = responseBody.substring(i, end);
        print("🔐 Login response chunk ${(i ~/ chunkSize) + 1}: $chunk");
      }

      return {
        'statusCode': response.statusCode,
        'body': response.body,
        'success': response.statusCode == 200,
      };
    } catch (e) {
      print('❌ Error in loginUser: $e');
      return {
        'statusCode': 0,
        'body': '',
        'success': false,
        'errorMessage': e is SocketException ? 'Network issue' : '',
      };
    }
  }

  /// Driver/Incharge session API call
  /// Fetches additional data for drivers/incharge users
  static Future<Map<String, dynamic>> fetchDriverSession({
    required int vmId,
    required String vsid,
  }) async {
    try {
      print('🚗 Fetching driver/incharge session data for vmId: $vmId');

      final response = await http.post(
        processSessionRequest,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'VMETID':
              'fG5k1mWf1OZYinDoY0evBxUZghzEKbrAYeHxQXR4rxFG2XqxVC1CgDUhyUMZM7V0ivoycMFgfIQOzKbug+G+bJVI3hz8Y45cPST676lSzGbR5LukGZECqIFu19CtIdhw/5obOGs1ZGE1MwKpebWTDhsfRL6adTdCUWB3YAQ8/a8pXYx8lACaEs9Ri2D2m7d+h+fOcdQQlpdlpdwxxLAVvnee8OYE39miaxpJFULkWCJhXomrQvOZjCGFzjAF9QWZuGshGb2Xl/gOutmzxplKIc8UBSwApq+6NLuaIsHc+MknqhonpGNq5JJQRRXKMXaVYbhdWDPXQZ8QqhfFrGpDTA==',
          'VSID': globalloginData?['vsid'] ?? vsid ?? '',
        },
        body: jsonEncode(<String, dynamic>{"vmId": vmId}),
      );

      print('🚗 Driver Session API Status: ${response.statusCode}');
      print('🚗 Driver Session API Body: ${response.body}');

      _checkSessionExpiration(response.body);

      return {
        'statusCode': response.statusCode,
        'body': response.body,
        'success': response.statusCode == 200,
      };
    } catch (e) {
      print('❌ Error in fetchDriverSession: $e');
      return {
        'statusCode': 0,
        'body': '',
        'success': false,
        'errorMessage': e is SocketException ? 'Network issue' : '',
      };
    }
  }


}