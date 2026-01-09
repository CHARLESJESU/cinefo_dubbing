import 'dart:convert';
import 'package:cinefo_dubbing/variables.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import '../../ApiCalls/apicall.dart' as apicalls;

class CreateCallsheetScreen extends StatefulWidget {
  const CreateCallsheetScreen({super.key});

  @override
  State<CreateCallsheetScreen> createState() => _CreateCallsheetScreenState();
}

class _CreateCallsheetScreenState extends State<CreateCallsheetScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  bool _isLoading = false;
  double _latitude = 0.0;
  double _longitude = 0.0;
  int _selectedShiftId = 0;
  String? _defaultCallsheetName;
  DateTime? _selectedDate;

  List<Map<String, dynamic>> _shifts = [
    {'id': 0, 'name': 'Select Shift'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
    _nameController.text = "";
    _getCurrentLocation();
  }

  Future<void> _initializeData() async {
    await apicalls.fetchloginDataFromSqlite();
    print("ennada");
    final shiftResponse = await apicalls.shiftlistshowcaseapi(
      productiontypeid: productionTypeId.toString() ?? '0',
    );
    
    if (shiftResponse['success'] == true) {
      try {
        final responseBody = json.decode(shiftResponse['body']);
        if (responseBody['responseData'] != null) {
          final List<dynamic> shiftData = responseBody['responseData'];
          setState(() {
            _shifts = [
              {'id': 0, 'name': 'Select Shift'},
              ...shiftData.map((shift) => {
                'id': shift['shiftId'] as int,
                'name': shift['shift'] as String,
              }).toList(),
            ];
          });
          print('✅ Loaded ${shiftData.length} shifts from API');
        }
      } catch (e) {
        print('❌ Error parsing shift response: $e');
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted)
          setState(
            () => _locationController.text = "Location services disabled",
          );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted)
            setState(
              () => _locationController.text = "Location permission denied",
            );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted)
          setState(
            () => _locationController.text =
                "Location permissions permanently denied",
          );
        return;
      }

      if (mounted)
        setState(
          () => _locationController.text = "Fetching accurate location...",
        );

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        ).timeout(const Duration(seconds: 10));

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          String fullLocation =
              "${place.name}, ${place.locality}, ${place.administrativeArea}";
          if (mounted) setState(() => _locationController.text = fullLocation);
        } else {
          if (mounted)
            setState(
              () => _locationController.text =
                  "Lat: ${position.latitude}, Long: ${position.longitude}",
            );
        }
      } catch (geocodingError) {
        print("Geocoding error: $geocodingError");
        // Fallback to coordinates if geocoding fails (e.g. no internet)
        if (mounted) {
          setState(() {
            _locationController.text =
                "Lat: ${position.latitude.toStringAsFixed(4)}, Long: ${position.longitude.toStringAsFixed(4)}";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(
          () =>
              _locationController.text = "Error: Use location button to retry",
        );
      }
      print("Error getting location: $e");
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedShiftId == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select a shift")));
      return;
    }
    if (_selectedDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select a date")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final createdAt = DateFormat('dd-MM-yyyy HH:mm:ss').format(now);
      final createdDate = DateFormat('dd-MM-yyyy').format(now);
      final createdAtTime = DateFormat('HH:mm:ss').format(now);

      final result = await apicalls.createCallSheetApi(
        selectedDate: DateFormat('dd-MM-yyyy').format(_selectedDate!),
        callsheetname: _nameController.text.trim(),
        shiftId: _selectedShiftId,
        latitude: _latitude,
        longitude: _longitude,
        location: _locationController.text,
        locationType: "In-station",
        locationTypeId: 1,
        createdAt: createdAt,
        createdDate: createdDate,
        createdAtTime: createdAtTime,
      );
      print("Create callsheet result: ${result['body']}");
      
      // Check for status 1030
      if (result['data'] != null && 
          (result['data']["status"] == "1030" || result['data']["status"] == 1030)) {
        final message = result['data']["message"] ?? 'An error occurred';
        if (mounted) {
          await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Notice'),
                content: Text(message),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
          Navigator.pop(context); // Navigate back
        }
      } else if (result['success']) {
        _showSuccess("Callsheet created successfully!");
        Navigator.pop(context);
      } else {
        final err = result['errorMessage'] ?? 'Failed to create callsheet';
        _showError(err);
      }
    } catch (e) {
      print("Error in _submitForm: $e");
      _showError('Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Create callsheet",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Add Your Details",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.grey.shade100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel("Shift"),
                      _buildDropdownField(
                        value: _selectedShiftId,
                        items: _shifts,
                        onChanged: (val) {
                          setState(() {
                            _selectedShiftId = val!;
                            final shift = _shifts.firstWhere(
                              (s) => s['id'] == val,
                            );
                            final shiftName = shift['name'] as String;
                            final match = RegExp(
                              r'\(([^)]+)\)',
                            ).firstMatch(shiftName);
                            final newDefault = match != null
                                ? (match.group(1) ?? '')
                                : '';
                            if (_nameController.text.isEmpty ||
                                _nameController.text == _defaultCallsheetName) {
                              _nameController.text = newDefault;
                              _defaultCallsheetName = newDefault;
                            } else {
                              _defaultCallsheetName = newDefault;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 15),
                      _buildFieldLabel("Date"),
                      _buildDatePickerField(),
                      const SizedBox(height: 15),
                      _buildFieldLabel("Callsheet name"),
                      _buildTextField(
                        controller: _nameController,
                        hint: "Enter callsheet name",
                      ),
                      const SizedBox(height: 15),
                      _buildFieldLabel("Location"),
                      _buildLocationField(),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1652f0),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Create",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        validator: (value) =>
            value == null || value.isEmpty ? "Required" : null,
      ),
    );
  }

  Widget _buildDropdownField({
    required int value,
    required List<Map<String, dynamic>> items,
    required Function(int?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          isExpanded: true,
          items: items.map((item) {
            return DropdownMenuItem<int>(
              value: item['id'],
              child: Text(
                item['name'],
                style: TextStyle(
                  color: item['id'] == 0 ? Colors.grey.shade500 : Colors.black,
                  fontSize: 14,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDatePickerField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: () async {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final initial = _selectedDate == null
              ? today
              : (_selectedDate!.isBefore(today) ? today : _selectedDate!);

          DateTime? picked = await showDatePicker(
            context: context,
            initialDate: initial,
            firstDate: today,
            lastDate: DateTime(2101),
          );
          if (picked != null) {
            setState(() {
              _selectedDate = picked;
            });
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedDate == null
                    ? "Select Date"
                    : DateFormat('dd-MM-yyyy').format(_selectedDate!),
                style: TextStyle(
                  color: _selectedDate == null
                      ? Colors.grey.shade400
                      : Colors.black,
                  fontSize: 14,
                ),
              ),
              Icon(
                Icons.calendar_today_outlined,
                color: Colors.grey.shade400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                hintText: "Enter location",
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.location_on,
              color: Colors.blue.shade600,
              size: 24,
            ),
            onPressed: _getCurrentLocation,
          ),
        ],
      ),
    );
  }
}
