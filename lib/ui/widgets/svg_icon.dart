import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class GameSvgIcon extends StatelessWidget {
  final String assetPath;
  final double size;
  final Color? color;

  const GameSvgIcon({
    super.key,
    required this.assetPath,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      colorFilter: color == null
          ? null
          : ColorFilter.mode(color!, BlendMode.srcIn),
    );
  }
}
