import 'dart:convert';
import 'package:flutter/material.dart';
import '../ApiCalls/apicall.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Role')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final id = item['id'];
                      final name = item['name'] ?? '';
                      final checked = _selectedIds.contains(id);
                      return CheckboxListTile(
                        title: Text(name),
                        value: checked,
                        onChanged: (v) {
                          setState(() {
                            if (v == true)
                              _selectedIds.add(id);
                            else
                              _selectedIds.remove(id);
                          });
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selectedIds.isEmpty ? null : _onSubmit,
                      child: const Text('Submit'),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
