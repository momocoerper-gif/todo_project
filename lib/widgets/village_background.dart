import 'package:flutter/material.dart';

import '../services/village_time_service.dart';

/// Pure presentation widget: time selection belongs to VillageScreen.
/// The image fills its parent's *world coordinates* without cropping.
class VillageBackground extends StatelessWidget {
  final VillageTime time;
  final bool isExpansion;

  const VillageBackground({
    super.key,
    required this.time,
    this.isExpansion = false,
  });

  @override
  Widget build(BuildContext context) {
    final timeName = switch (time) {
      VillageTime.morning => 'morning',
      VillageTime.day => 'day',
      VillageTime.evening => 'evening',
      VillageTime.night => 'night',
    };
    final imagePath = isExpansion
        ? 'assets/images/village/expansion_01/expansion_$timeName.png'
        : VillageTimeService.imageFor(time);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 1600),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      layoutBuilder: (currentChild, previousChildren) => Stack(
        fit: StackFit.expand,
        children: [...previousChildren, if (currentChild != null) currentChild],
      ),
      child: Image.asset(
        imagePath,
        key: ValueKey(imagePath),
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.fill,
        filterQuality: FilterQuality.none,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => const ColoredBox(
          color: Color(0xFF456B46),
          child: Center(
            child: Text(
              'Dorfgrafik konnte nicht geladen werden.',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
