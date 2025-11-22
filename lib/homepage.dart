import 'package:brain_circle/pages/goals.dart';
import 'package:brain_circle/pages/home.dart';
import 'package:brain_circle/pages/statistics.dart';
import 'package:flutter/material.dart';
import 'package:brain_circle/pages/account_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Homepage extends StatefulWidget {
  Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int currentPageIndex = 0;
  final _pageController = PageController();

  final user = FirebaseAuth.instance.currentUser;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar: AppBar(
              centerTitle: true,
              title: Text("Hello, ${user!.displayName?.split(' ').first}!"),
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              actions: [
                IconButton(
                  tooltip: 'Account',
                  icon: const Icon(Icons.account_circle_outlined),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AccountPage(),
                      ),
                    );
                  },
                ),
              ],
       ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        children: [Home(), Goals(), Statistics()],
      ),
      bottomNavigationBar: NavigationBar(
        destinations: [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.flag), label: 'Goals'),
          NavigationDestination(
            icon: Icon(Icons.stacked_bar_chart),
            label: 'Statistics',
          ),
        ],
        selectedIndex: currentPageIndex,
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          });
        },
      ),
    );
  }
}
