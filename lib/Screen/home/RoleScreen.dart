import 'dart:convert';
import 'package:flutter/material.dart';
import '../../ApiCalls/apicall.dart';
import '../../colorcode/colorcode.dart';

class RoleScreen extends StatefulWidget {
  const RoleScreen({super.key});

  @override
  State<RoleScreen> createState() => _RoleScreenState();
}

class _RoleScreenState extends State<RoleScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];
  final Set<dynamic> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadConfigs();
  }

  Future<void> _loadConfigs() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await forouttimelookupapi();
      if (res['statusCode'] == 200 && res['body'] != null) {
        final decoded = jsonDecode(res['body']);
        List raw = [];
        if (decoded is List)
          raw = decoded;
        else if (decoded is Map && decoded['responseData'] is List)
          raw = decoded['responseData'];
        else if (decoded is Map && decoded['dubbingConfigName'] != null)
          raw = [decoded];

        _items = raw
            .map<Map<String, dynamic>>(
              (e) => {
                'id': e['dubbingConfigId'],
                'name':
                    e['dubbingConfigName'] ??
                    e['dubbing_name'] ??
                    e['name'] ??
                    '',
              },
            )
            .where((m) => m['id'] != null)
            .toList();
      } else {
        _error = 'Failed to load roles';
      }
    } catch (e) {
      _error = 'Error loading roles';
    }

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  void _onSubmit() {
    // Print selected dubbingConfigId(s) to console
    print('Selected dubbingConfigId(s): ${_selectedIds.toList()}');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Submitted Successfully')));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(decoration: AppColors.gradientBackground),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text(
              'Select Role',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : _error != null
                  ? Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _items.length,
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              final id = item['id'];
                              final name = item['name'] ?? '';
                              final checked = _selectedIds.contains(id);
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: CheckboxListTile(
                                  title: Text(
                                    name,
                                    style: TextStyle(
                                      fontWeight: checked
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: checked
                                          ? AppColors.primaryDark
                                          : Colors.grey[800],
                                    ),
                                  ),
                                  value: checked,
                                  activeColor: AppColors.primaryDark,
                                  checkColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  onChanged: (v) {
                                    setState(() {
                                      if (v == true)
                                        _selectedIds.add(id);
                                      else
                                        _selectedIds.remove(id);
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          child: SafeArea(
                            child: SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed:
                                    _selectedIds.isEmpty ? null : _onSubmit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.primaryDark,
                                  disabledBackgroundColor:
                                      Colors.grey.withOpacity(0.3),
                                  disabledForegroundColor: Colors.grey,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Submit (${_selectedIds.length})',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
        ),
      ],
    );
  }
}
