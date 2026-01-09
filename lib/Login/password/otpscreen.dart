import 'dart:convert';
import 'package:cinefo_dubbing/Login/password/passwordapi.dart';
import 'package:cinefo_dubbing/Login/password/setpasswordscreen.dart';
import 'package:cinefo_dubbing/colorcode/colorcode.dart';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class OtpVerifyScreen extends StatefulWidget {
  final String? phoneNumber;

  const OtpVerifyScreen({super.key, required this.phoneNumber});

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  String otpValue = '';
  String? otpError;
  bool isLoading = false;

  void validateOtp(String value) {
    setState(() {
      if (value.isEmpty) {
        otpError = 'OTP is required';
      } else if (value.length != 6) {
        otpError = 'OTP must be 4 digits';
      } else if (!RegExp(r'^\d{6}$').hasMatch(value)) {
        otpError = 'OTP must contain only digits';
      } else {
        otpError = null;
      }
    });
  }

  Future<void> verifyButton() async {
    validateOtp(otpValue);

    if (otpError == null && otpValue.length == 6) {
      setState(() {
        isLoading = true;
      });
      try {
        final int mobileOtp = int.parse(otpValue);

        final dynamic rawResult = await otpscreenapi(mobileOtp);

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
                        SetPasswordScreen(phoneNumber: widget.phoneNumber),
                  ),
                );
                return;
              }
            } else {
              String errorMessage = 'Otp is invalild';
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
          content: Text('OTP is invalid'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // -------- TOP IMAGE --------

                // -------- TITLE --------
                const Text(
                  "Verify Code",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryLight,
                  ),
                ),

                const SizedBox(height: 10),

                // -------- SUBTITLE --------
                Text(
                  "Please enter the code we just sent\nto the number ${widget.phoneNumber}",
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),

                const SizedBox(height: 30),

                // -------- OTP FIELD --------
                PinCodeTextField(
                  appContext: context,
                  length: 6,
                  keyboardType: TextInputType.number,
                  animationType: AnimationType.fade,
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.box,
                    borderRadius: BorderRadius.circular(10),
                    fieldHeight: 45,
                    fieldWidth: 45,
                    activeColor: Colors.grey.shade300,
                    inactiveColor: Colors.grey.shade300,
                    selectedColor: Colors.orange,
                    activeFillColor: const Color(0xFFFFF2CC),
                    inactiveFillColor: const Color(0xFFFFF2CC),
                    selectedFillColor: const Color(0xFFFFF2CC),
                  ),
                  enableActiveFill: true,
                  onChanged: (value) {
                    otpValue = value;
                    // Optional: live-validate as user types
                    if (otpError != null) validateOtp(value);
                  },
                ),

                if (otpError != null) ...[
                  const SizedBox(height: 8),
                  Text(otpError!, style: const TextStyle(color: Colors.red)),
                ],

                const SizedBox(height: 10),

                // ---------- RESEND CODE ----------
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Didn't receive OTP? ",
                      style: TextStyle(color: Colors.grey),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: const Text(
                        "Resend Code",
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // ---------- VERIFY BUTTON (Gradient) ----------
                Container(
                  width: double.infinity,
                  height: 55,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColors.primaryGradient,
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            verifyButton();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            "Verify",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
