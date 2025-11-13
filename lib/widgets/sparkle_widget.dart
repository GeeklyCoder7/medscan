import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SparkleIcon extends StatelessWidget {
  final Animation<double> animation;

  const SparkleIcon({Key? key, required this.animation}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: (animation.value * 2).clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 0.5 + (animation.value * 0.5),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: Colors.amber,
              size: 16,
            ),
          ),
        );
      },
    );
  }
}
