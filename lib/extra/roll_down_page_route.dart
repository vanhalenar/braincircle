import 'package:flutter/material.dart';

class RollDownPageRoute extends PageRouteBuilder {
  final Widget page;
  final Color appBarColor;

  RollDownPageRoute({required this.page, required this.appBarColor})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: const Duration(milliseconds: 600),
        reverseTransitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Get the AppBar height
          final appBarHeight =
              kToolbarHeight + MediaQuery.of(context).padding.top;
          final screenHeight = MediaQuery.of(context).size.height;

          // Create curved animation
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          );

          return AnimatedBuilder(
            animation: curvedAnimation,
            builder: (context, _) {
              final progress = curvedAnimation.value;

              // Once animation is complete, just show the themed child
              if (progress == 1.0) {
                return Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(scaffoldBackgroundColor: appBarColor),
                  child: child,
                );
              }

              // Calculate the height of the expanding green area
              final expandedHeight =
                  appBarHeight + (screenHeight - appBarHeight) * progress;

              return Stack(
                children: [
                  // The new page (transparent during animation)
                  Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(scaffoldBackgroundColor: Colors.transparent),
                    child: child,
                  ),
                  // The expanding green rectangle (simulates AppBar rolling down)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: expandedHeight,
                    child: Container(color: appBarColor),
                  ),
                ],
              );
            },
          );
        },
      );
}
