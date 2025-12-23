// import 'package:flutter/material.dart';
//
// import 'package:production/Screens/Home/MyHomescreen.dart';
// import 'package:production/Screens/Home/driverhomescreen.dart';
// import 'package:production/Screens/report/DriverReport.dart';
//
// import 'package:production/Screens/report/InchargeReports.dart';
// import 'package:production/variables.dart';
//
// class Routescreenfordriver extends StatefulWidget {
//   final int initialIndex;
//
//   const Routescreenfordriver(
//       {super.key, this.initialIndex = 0}); // Default to Home tab
//
//   @override
//   State<Routescreenfordriver> createState() => _RoutescreenfordriverState();
// }
//
// class _RoutescreenfordriverState extends State<Routescreenfordriver> {
//   int _currentIndex = 0;
//
//   @override
//   void initState() {
//     super.initState();
//     _currentIndex = widget.initialIndex; // Set initial tab from parameter
//   }
//
//   void _onItemTapped(int index) {
//     setState(() {
//       _currentIndex = index;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Color(0xFF355E8C),
//       body: Stack(
//         children: [
//           SafeArea(
//             child: _getScreenWidget(_currentIndex),
//           ),
//           Align(
//             alignment: Alignment.bottomCenter,
//             child: SafeArea(
//               top: false,
//               child: SizedBox(
//                 height: 70,
//                 child: Stack(
//                   children: [
//                     BottomNavigationBar(
//                       backgroundColor: Color(0xFF355E8C),
//                       items: const [
//                         BottomNavigationBarItem(
//                           icon: Icon(Icons.home),
//                           label: 'Home',
//                         ),
//                         // BottomNavigationBarItem(
//                         //   icon: Icon(Icons.add_circle_outline),
//                         //   label: 'Callsheet',
//                         // ),
//                         BottomNavigationBarItem(
//                           icon: Icon(Icons.calendar_month),
//                           label: 'Reports',
//                         ),
//                         // BottomNavigationBarItem(
//                         //   icon: Icon(Icons.trip_origin),
//                         //   label: 'Trip',
//                         // ),
//                       ],
//                       currentIndex: _currentIndex,
//                       onTap: _onItemTapped,
//                       selectedItemColor: Colors.white,
//                       unselectedItemColor: Colors.white,
//                       showUnselectedLabels: true,
//                       type: BottomNavigationBarType.fixed,
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _getScreenWidget(int index) {
//     switch (index) {
//       case 0:
//         // return const MovieListScreen();
//         return const DriverMyhomescreen();
//       // case 1:
//       //   if (productionTypeId == 3) {
//       //     return (selectedProjectId != null && selectedProjectId != "0")
//       //         ? CallSheet()
//       //         : const MovieListScreen();
//       //   } else {
//       //     // For productionTypeId == 2 or any other case
//       //     return CallSheet();
//       //   }
//
//       case 1:
//         return Driverreport();
//       // case 3:
//       //   return TripScreen();
//       default:
//         return const MyHomescreen();
//     }
//   }
// }
