import 'package:flutter/material.dart';

class CustomNavbar extends StatefulWidget {
  const CustomNavbar({super.key});

  @override
  State<CustomNavbar> createState() => _CustomNavbarState();
}

class _CustomNavbarState extends State<CustomNavbar> {
  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      destinations: [
        NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.flag), label: 'Goals'),
        NavigationDestination(
          icon: Icon(Icons.stacked_bar_chart),
          label: 'Statistics',
        ),
      ],
      selectedIndex: 0,
      onDestinationSelected: (int index) {
        setState(() {
        });
      },
    );
  }
}
