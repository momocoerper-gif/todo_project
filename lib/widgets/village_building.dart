
import 'package:flutter/material.dart';

class VillageBuilding extends StatelessWidget {
  final String imagePath;
  final String name;
  final VoidCallback onTap;

  const VillageBuilding({
    super.key,
    required this.imagePath,
    required this.name,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$name öffnen',
      child: Tooltip(
        message: name,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: Colors.amber.withValues(alpha: 0.12),
            highlightColor:
                Colors.amber.withValues(alpha: 0.08),
            child: AnimatedSwitcher(
              duration: const Duration(seconds: 2),
              child: Image.asset(
                imagePath,
                key: ValueKey(imagePath),
                fit: BoxFit.contain,
                filterQuality: FilterQuality.none,
                gaplessPlayback: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
