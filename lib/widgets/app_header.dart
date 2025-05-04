// lib/widgets/app_header.dart
import 'package:flutter/material.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Coffee background image
        Container(
          color: Colors.black,
          width: double.infinity,
          height: 200,
          child: Image.asset(
            'assets/images/header_3.png',
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: double.infinity,
                height: 200,
                color: const Color(0xFFE3D0BA),
              );
            },
          ),
        ),

        // App bar with profile
        // SafeArea(
        //   child: Padding(
        //     padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        //     child: Row(
        //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //       children: [
        //         const Text(
        //           'Mocha \nPoint',
        //           style: TextStyle(
        //             color: Colors.white,
        //             fontSize: 22,
        //             fontWeight: FontWeight.bold,
        //             fontFamily: 'Mocha',
        //           ),
        //         ),
        //         Row(
        //           children: [
        //             GestureDetector(
        //               onTap: () {
        //                 // Navigate to profile (tabIndex 3)
        //                 final homeState = context.findAncestorStateOfType<_HomeScreenState>();
        //                 if (homeState != null) {
        //                   homeState.setState(() {
        //                     homeState._selectedIndex = 3;
        //                   });
        //                 }
        //               },
        //               child: Container(
        //                 decoration: const BoxDecoration(
        //                   shape: BoxShape.circle,
        //                   color: Colors.white,
        //                 ),
        //                 padding: const EdgeInsets.all(2),
        //                 child: ClipOval(
        //                   child: Image.asset(
        //                     'assets/images/profile.png',
        //                     width: 60,
        //                     height: 60,
        //                     errorBuilder: (context, error, stackTrace) {
        //                       return const Icon(
        //                         Icons.person,
        //                         size: 20,
        //                         color: Colors.black54,
        //                       );
        //                     },
        //                   ),
        //                 ),
        //               ),
        //             ),
        //           ],
        //         ),
        //       ],
        //     ),
        //   ),
        // ),
      ],
    );
  }
}