import 'dart:convert';
import 'package:cinefo_dubbing/Login/loginscreen.dart';
import 'package:cinefo_dubbing/Login/password/otpscreen.dart';
import 'package:cinefo_dubbing/Login/password/passwordapi.dart' as api;
import 'package:cinefo_dubbing/colorcode/colorcode.dart';
import 'package:cinefo_dubbing/variables.dart';
import 'package:flutter/material.dart';
import '../../Login/logindataapiservice.dart';

class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({super.key});

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final TextEditingController phoneController = TextEditingController();
  String? phoneError;
  // loading state to show buffering in the submit button
  bool isLoading = false;

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  void validatePhoneNumber(String value) {
    setState(() {
      if (value.isEmpty) {
        phoneError = "Phone number is required";
      } else if (value.length != 10) {
        phoneError = "Phone number must be exactly 10 digits";
      } else if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
        phoneError = "Phone number must contain only digits";
      } else {
        phoneError = null;
      }
    });
  }

  Future<void> submitPhoneNumber() async {
    validatePhoneNumber(phoneController.text);

    if (phoneError == null && phoneController.text.length == 10) {
      setState(() {
        isLoading = true;
      });
      try {
        emailOrPhone = phoneController.text;
        await LoginApiService.fetchBaseUrl(dancebaseurl);
        final dynamic rawResult = await api.forgetpasswordapi();

        if (rawResult is Map<String, dynamic>) {
          final dynamic bodyData = rawResult['body'];
          Map<String, dynamic>? body;

          if (bodyData is String) {
            try {
              body = jsonDecode(bodyData) as Map<String, dynamic>;
            } catch (e) {
              body = null;
            }
          } else if (bodyData is Map<String, dynamic>) {
            body = bodyData;
          }

          if (body != null) {
            final String? statusCode = body['statusCode']?.toString();

            if (statusCode == "200") {
              if (mounted) {
                // stop loading before navigation to avoid state updates after navigation issues
                setState(() {
                  isLoading = false;
                });
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        OtpVerifyScreen(phoneNumber: emailOrPhone),
                  ),
                );
                return;
              }
            } else {
              String errorMessage = 'Phone number not found';
              final String? errorDesc = body['errordescription']?.toString();
              if (errorDesc != null && errorDesc.isNotEmpty) {
                errorMessage = errorDesc;
              }

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(errorMessage),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Invalid response format'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Invalid response format'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Network error. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        // ensure loading is stopped unless we've already navigated away
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number is invalid'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: screenHeight * 0.025),

                // ---------- TITLE ----------
                Text(
                  "Forget Password",
                  style: TextStyle(
                    fontSize: screenWidth * 0.06,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryLight,
                  ),
                ),

                SizedBox(height: screenHeight * 0.01),

                // ---------- SUBTITLE ----------
                Text(
                  "Enter your registered Phone Number below",
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    color: Colors.grey,
                  ),
                ),

                SizedBox(height: screenHeight * 0.03),

                // ---------- PHONE LABEL ----------
                Text(
                  "Phone",
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryLight,
                  ),
                ),

                SizedBox(height: screenHeight * 0.012),

                // ---------- PHONE TEXT FIELD ----------
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  onChanged: validatePhoneNumber,
                  style: TextStyle(fontSize: screenWidth * 0.04),
                  decoration: InputDecoration(
                    hintText: "Enter your phone number",
                    hintStyle: TextStyle(fontSize: screenWidth * 0.038),
                    filled: true,
                    fillColor: Colors.yellow.shade50,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenHeight * 0.017,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                      borderSide: BorderSide.none,
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                    errorText: phoneError,
                    errorStyle: TextStyle(fontSize: screenWidth * 0.033),
                    counterText: "", // Hide the character counter
                  ),
                ),

                SizedBox(height: screenHeight * 0.012),

                // ---------- SIGN IN LINK ----------
                Row(
                  children: [
                    Text(
                      "Remember the password?",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: screenWidth * 0.035,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Loginscreen(),
                          ),
                        );
                      },
                      child: Text(
                        "Sign in",
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: screenWidth * 0.035,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: screenHeight * 0.05),

                // ---------- GRADIENT SUBMIT BUTTON ----------
                Container(
                  width: double.infinity,
                  height: screenHeight * 0.065,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColors.primaryGradient,
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  ),
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                            await submitPhoneNumber();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.03),
                      ),
                    ),
                    child: isLoading
                        ? SizedBox(
                            width: screenWidth * 0.06,
                            height: screenWidth * 0.06,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            "Submit",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.045,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                SizedBox(height: screenHeight * 0.025),
              ], // children
            ), // Column
          ), // Padding
        ), // SingleChildScrollView
      ), // SafeArea
    ); // Scaffold
  }
}
