import 'package:flutter/material.dart';


class ProvideLoadingTask extends StatelessWidget {

  final isLoading;
  final Widget child;

  ProvideLoadingTask({required this.isLoading, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
}