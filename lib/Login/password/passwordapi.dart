import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cinefo_dubbing/variables.dart';

Future<Map<String, dynamic>> forgetpasswordapi() async {
  try {
    final payload = {
      "emailOrPhone": emailOrPhone ?? '',
      "vpid": baseurlresult?['vpid'] ?? vpid ?? 0,
      "vpoid": baseurlresult?['vpoid'] ?? vpoid ?? 0,
      // Some responses use the key 'vptemplteID' (typo) while others use 'vptemplateID'.
      "vptemplateID": baseurlresult?['vptemplateID'] ?? vptemplateID ?? 0,

      "ssoGroupId": baseurlresult?['ssoGroupId'] ?? ssoGroupId ?? 0,
    };
    print("🚗🚗🚗🚗🚗 $processRequest");
    final forgetpasswordresponse = await http.post(
      processRequest,
      headers: <String, String>{
        'VMETID':
            'QdWRFxjLomN7fm53tw251rEwBZZs+jZ1f6hmAHWFziyzV3/Mx5iI6cDdYuQlvAxBQwCa/Yc//pkXk94umWd+ebP3/d3P9CkPhJGokxsvGUPAWR02Ep/0lqOpamNbtoEHs/36XdyRR96on5H/BMhFFpusj2T4bhRGjXD25ZrNbJrahSCCNcXx777CRXLFZlPpYVycckr06Q1o75UEb6gDWtCil0A+m94Wm8nkD4QbJJeQ+6g1GY+hvFcBIdTt62r8ip+CMz+ouMs9vDuEisU2DuxyN06UBeb0LhVUVWHSkYeA/s8bq+iaKGPHlh6SEbVn8xYxXbJfT3tcusz0TT5qzA==',
      },
      body: jsonEncode(payload),
    );

    print(
      '🚗 forgetpasswordresponse Status API Response Status: ${forgetpasswordresponse.statusCode}',
    );
    print('🚗 forgetpasswordresponse Status API Response Status: ${payload}');
    print(
      '🚗 forgetpasswordresponse Status API Response Body: ${forgetpasswordresponse.body}',
    );
    if (forgetpasswordresponse.statusCode == 200) {
      final responseBody = json.decode(forgetpasswordresponse.body);
      final responseBody2 = responseBody["responseData"];
      if (responseBody2 != null) {
        final responseBody3 = responseBody2["userEntity"];
        print(responseBody3);
        if (responseBody3 != null) {
          forgetpasswordresponseresult = responseBody3;
          print(forgetpasswordresponseresult);
          vmid = forgetpasswordresponseresult?['vmid'] ?? 0;
          vuid = forgetpasswordresponseresult?['vuid'] ?? 0;
          print("🚗🚗🚗🚗🚗$vmid");
          mobileValidateType =
              forgetpasswordresponseresult?['mobileValidateType'] ?? 0;
        } else {
          print('Invalid base URL response structure: userEntity is null');
        }
      } else {
        print('Invalid base URL response structure: responseData is null');
      }
    } else {
      print('Failed to get base URL: ${forgetpasswordresponse.statusCode}');
    }
    return {
      'statusCode': forgetpasswordresponse.statusCode,
      'body': forgetpasswordresponse.body,
      'success': forgetpasswordresponse.statusCode == 200,
    };
  } catch (e) {
    print('❌ Error in tripstatusapi: $e');
    return {'statusCode': 0, 'body': 'Error: $e', 'success': false};
  }
}

Future<Map<String, dynamic>> otpscreenapi(int mobileotp) async {
  try {
    final payload = {
      "mobileOTP": "$mobileotp",
      "vmid": forgetpasswordresponseresult?['vmid'] ?? vmid ?? 0,
      "vpid": forgetpasswordresponseresult?['vpid'] ?? vpid ?? 0,
      "vptemplateId": baseurlresult?['vptemplateID'] ?? vptemplateID ?? 0,
      "mobileValidationType":
          baseurlresult?['mobileValidateType'] ?? mobileValidateType ?? 0,
    };
    print("🚗🚗🚗🚗🚗 $processRequest");
    print('Sending OTP payload: ${jsonEncode(payload)}');
    final otpverifyresponse = await http.post(
      processRequest,
      headers: <String, String>{
        'VMETID':
            'GmUcLPd+XYnnVfOGKS4KXLDXIwb/n45Q7mAe8q4bhmGyCitXBeT8ieAedPusUt34f2QvqYcNpGUybz1N9gxIadwiUoeEgaZ2NEypQpX1JQLFDshW5eb1Wv0r1V64cn7u9LDAQ9aa4f3fkK21gP6hSrs3sXsb0xu5YAtN0DIZmLdh7OjkCGLY0BUhV//iAmNb29cXjfc2D0dDKnNpauUBFtA0AA0qBJkkL6efHLU8MkR2ivDI1m/yrp5hNgG+KIa4FfaDZ/+qOHfxyar49E5kcD9sHshQfZSVLERswXBAt/E+Y4GhrLVcNrss201tv1E/R1rCTTjktZnQzfze0LXFAw==',
      },
      body: jsonEncode(payload),
    );

    print(
      '🚗 otpverifyresponse Status API Response Status: ${otpverifyresponse.statusCode}',
    );
    print('🚗 otpverifyresponse Status API Response Status: ${payload}');
    print(
      '🚗 otpverifyresponse Status API Response Body: ${otpverifyresponse.body}',
    );
    if (otpverifyresponse.statusCode == 200) {
      final responseBody = json.decode(otpverifyresponse.body);
      print(responseBody);
      if (responseBody != null && responseBody['responseData'] != null) {
        otpverifyresponseresult = responseBody['responseData'];
        print(otpverifyresponseresult);
      } else {
        print('Invalid base URL response structure');
      }
    } else {
      print('Failed to get base URL: ${otpverifyresponse.statusCode}');
    }
    return {
      'statusCode': otpverifyresponse.statusCode,
      'body': otpverifyresponse.body,
      'success': otpverifyresponse.statusCode == 200,
    };
  } catch (e) {
    print('❌ Error in tripstatusapi: $e');
    return {'statusCode': 0, 'body': 'Error: $e', 'success': false};
  }
}

Future<Map<String, dynamic>> setpasswordapi(String? password) async {
  try {
    final payload = {
      "vmid": otpverifyresponseresult?['vmid'] ?? vmid ?? 0,
      "vuid": otpverifyresponseresult?['vuid'] ?? vuid ?? 0,
      "password": password ?? "",
      "vptemplateId":
          otpverifyresponseresult?['vptemplateID'] ?? vptemplateID ?? 0,
    };
    print("🚗🚗🚗🚗🚗 $processRequest");
    print('Sending OTP payload: ${jsonEncode(payload)}');
    final changepasswordresponse = await http.post(
      processRequest,
      headers: <String, String>{
        'VMETID':
            'aD4Z+enT2caurgFinTRqwwoIEcroxX87CSQpXg7C1BxiMRgr3WUo7YdGKgvWJWLB508/zo/EGDjNZ0CTl9ymrUuFYnrcv4qytu8NJ6TKlUfdyb3FKjRWXv31e41B/iZ31Zq/iw7eXi2PwuhZa0jEYTybhc1O8xicUFQ8QDjy/MHV4LL6614g5X/6lJVd7n0S6K+rXl/WuuPXv/7J3+v0bZ6XkBwqRSaamX+FPOR3Qx4BbY/Ijsk4lXVC6tcmDd2kmE+pndE6k9GaN7A+c59tHc0HJM0hOBlj4gcpRx6EjLIRspQ/dI47nfEwqDFcPiHliVRK3QvFFze7M4WK81/Xnw==',
      },
      body: jsonEncode(payload),
    );

    print(
      '🚗 changepasswordresponse Status API Response Status: ${changepasswordresponse.statusCode}',
    );
    print('🚗 changepasswordresponse Status API Response Status: ${payload}');
    print(
      '🚗 changepasswordresponse Status API Response Body: ${changepasswordresponse.body}',
    );

    return {
      'statusCode': changepasswordresponse.statusCode,
      'body': changepasswordresponse.body,
      'success': changepasswordresponse.statusCode == 200,
    };
  } catch (e) {
    print('❌ Error in changepasswordresponse: $e');
    return {'statusCode': 0, 'body': 'Error: $e', 'success': false};
  }
}

Future<Map<String, dynamic>> changepasswordapi(
  String? oldpassword,
  String? newpassword,
) async {
  try {
    final payload = {
      "vuid": globalloginData?['vuid'],
      "mobileNumber": globalloginData?['mobile_number'] ?? '',
      "password": oldpassword,
      "newpassword": newpassword,
    };
    print("🚗🚗🚗🚗🚗 $processRequest");
    print('Sending OTP payload: ${jsonEncode(payload)}');
    print(globalloginData?['vsid']);
    final changepasswordresponse = await http.post(
      processSessionRequest,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'VMETID':
            'mAgpajsKo9pVRfBicuVsGkzZG986GWPpxfGpbR9A2ysD1WGBMyqj2gL4NTftf7VABJvOG5KZ9iTW4ybk3oYbnO32oL+b08Ba9MW5pRlI6HaDbOb9pU4iH4VxGB79hQS+27ZzZuTOa9a4e8FrO3ASPC4B21zbSa19fJg1elJ/QK/PkA435B0vpMPKmp4vxfy0/tOEuO3yk5OuykSdwjBHoylNcqeZ2YeUaKeO5W9RwdfKDNMA50GTKxK80PrNQ7RlHJHuYH1NuO84hOvinlrITWc/+MPut0ePT14GyygBCVhRfWioIp3Qyxd+QENfFgqc7UwX8Q8MWERGf5uybUU1Pg==',
        'VSID': globalloginData?['vsid'] ?? "",
      },
      body: jsonEncode(payload),
    );

    print(
      '🚗 changepasswordresponse Status API Response Status: ${changepasswordresponse.statusCode}',
    );
    print('🚗 changepasswordresponse Status API Response Status: ${payload}');
    print(
      '🚗 changepasswordresponse Status API Response Body: ${changepasswordresponse.body}',
    );

    return {
      'statusCode': changepasswordresponse.statusCode,
      'body': changepasswordresponse.body,
      'success': changepasswordresponse.statusCode == 200,
    };
  } catch (e) {
    print('❌ Error in changepasswordresponse: $e');
    return {'statusCode': 0, 'body': 'Error: $e', 'success': false};
  }
}
