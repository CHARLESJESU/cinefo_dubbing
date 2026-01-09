import 'package:flutter/material.dart';
import '../Screen/home/HomeScreen.dart';
import '../Screen/report/Reportforcallsheet.dart';
import '../Screen/callsheet/callsheet.dart';

class RoutescreenforDubbingIncharge extends StatefulWidget {
  final int initialIndex;

  const RoutescreenforDubbingIncharge({
    super.key,
    this.initialIndex = 0,
    required Map<String, dynamic> callsheet,
  }); // Default to Home tab

  @override
  State<RoutescreenforDubbingIncharge> createState() =>
      _RoutescreenforDubbingInchargeState();
}

class _RoutescreenforDubbingInchargeState
    extends State<RoutescreenforDubbingIncharge> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex; // Set initial tab from parameter
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF355E8C),

      body: SafeArea(child: _getScreenWidget(_currentIndex)),

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color(0xFF355E8C),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Callsheet'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Reports',
          ),
        ],
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  Widget _getScreenWidget(int index) {
    switch (index) {
      case 0:
        return const MyHomeScreen();
      case 1:
        return const CallsheetScreen(); // Mapping Callsheet list tab
      case 2:
        return const Reportforcallsheet(); // Mapping Reports tab
      default:
        return const MyHomeScreen();
    }
  }
}
