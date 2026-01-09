import 'package:cinefo_dubbing/ApiCalls/apicall.dart';
import 'package:cinefo_dubbing/Login/loginscreen.dart';
import 'package:cinefo_dubbing/Login/password/passwordapi.dart';
import 'package:cinefo_dubbing/Route/RouteScreenfordubbingincharge.dart';
import 'package:cinefo_dubbing/colorcode/colorcode.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

class ChangepasswordScreen extends StatefulWidget {
  final String? phoneNumber;
  const ChangepasswordScreen({Key? key, this.phoneNumber}) : super(key: key);

  @override
  State<ChangepasswordScreen> createState() => _ChangepasswordScreenState();
}

class _ChangepasswordScreenState extends State<ChangepasswordScreen> {
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController oldPasswordController = TextEditingController();
  String? passwordError;
  bool isLoading = false;
  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  bool validatePasswords() {
    setState(() {
      final oldPass = oldPasswordController.text.trim();
      final newPass = newPasswordController.text.trim();
      final confirmPass = confirmPasswordController.text.trim();

      if (oldPass.isEmpty) {
        passwordError = 'Old password is required';
      } else if (newPass.isEmpty || confirmPass.isEmpty) {
        passwordError = 'Both password fields are required';
      } else if (newPass.length < 6) {
        passwordError = 'Password must be at least 6 characters';
      } else if (newPass != confirmPass) {
        passwordError = 'Passwords do not match';
      } else {
        passwordError = null;
      }
    });

    final valid = passwordError == null;
    if (valid) {
      // If validation passes, proceed to perform the reset action
      resetPasswordButton();
    }
    return valid;
  }

  Future<void> resetPasswordButton() async {
    // Assumes validation already performed by validatePasswords()
    setState(() {
      isLoading = true;
    });

    try {
      await fetchloginDataFromSqlite();
      // Call API - passing the confirm password
      final dynamic rawResult = await changepasswordapi(
        oldPasswordController.text.trim(),
        confirmPasswordController.text.trim(),
      );

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
              // stop loading before navigation to avoid state updates after navigation
              setState(() {
                isLoading = false;
              });
              
              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password changed successfully!'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
              
              // Navigate after a short delay to show the success message
              Future.delayed(const Duration(seconds: 1), () {
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => RoutescreenforDubbingIncharge()),
                    (route) => false,
                  );
                }
              });
              return;
            }
          } else {
            String errorMessage = 'Failed to reset password';
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
          SnackBar(
            content: Text('Network error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    oldPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              /// Title
              const Text(
                "Set New Password",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryLight,
                ),
              ),

              const SizedBox(height: 6),

              /// Subtitle
              const Text(
                "Enter a different password than the previous",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),

              const SizedBox(height: 30),

              /// Old Password TextField
              TextField(
                controller: oldPasswordController,
                obscureText: _obscureOldPassword,
                decoration: InputDecoration(
                  labelText: "Old Password",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureOldPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureOldPassword = !_obscureOldPassword;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// New Password TextField
              TextField(
                controller: newPasswordController,
                obscureText: _obscureNewPassword,
                decoration: InputDecoration(
                  labelText: "New Password",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNewPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureNewPassword = !_obscureNewPassword;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// Confirm Password TextField
              TextField(
                controller: confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: "Confirm Password",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
              ),

              if (passwordError != null) ...[
                const SizedBox(height: 8),
                Text(passwordError!, style: const TextStyle(color: Colors.red)),
              ],

              const SizedBox(height: 40),

              /// Bottom Image
              const SizedBox(height: 30),

              /// Reset Password Button (Gradient)
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
                          print(widget.phoneNumber);
                          validatePasswords();
                          Navigator.pop(context);
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
                          "Change Password",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
