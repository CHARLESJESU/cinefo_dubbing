import 'dart:convert';
import 'package:flutter/material.dart';
import '../../colorcode/colorcode.dart';

class RoledialogScreen extends StatefulWidget {
  const RoledialogScreen({super.key});

  @override
  State<RoledialogScreen> createState() => _RoledialogScreenState();
}

class _RoledialogScreenState extends State<RoledialogScreen> {
  // Map to store checkbox states (0 or 1)
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

  // Display labels for each field
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

  void _onSubmit() {
    // Print the map with selected values
    print('Selected configuration map:');
    print(jsonEncode(_configMap));
    // Return the config map to the caller
    Navigator.pop(context, _configMap);
  }

  @override
  Widget build(BuildContext context) {
    final keys = _configMap.keys.toList();
    
    return Stack(
      children: [
        Container(decoration: AppColors.gradientBackground),
        Scaffold(
          backgroundColor: Colors.transparent,
          
          appBar: AppBar(
            automaticallyImplyActions: false,
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
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: keys.length,
                  itemBuilder: (context, index) {
                    final key = keys[index];
                    final label = _labels[key] ?? key;
                    final checked = _configMap[key] == 1;
                    
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
                          label,
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
                            _configMap[key] = (v == true) ? 1 : 0;
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
                      onPressed: _selectedCount == 0 ? null : _onSubmit,
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
                        'Submit ($_selectedCount)',
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
