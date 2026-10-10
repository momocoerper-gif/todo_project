
import 'dart:async';

import 'package:flutter/material.dart';
import '../services/village_time_service.dart';

class VillageBackground extends StatefulWidget {
  const VillageBackground({super.key});

  @override
  State<VillageBackground> createState() =>
      _VillageBackgroundState();
}

class _VillageBackgroundState extends State<VillageBackground>
    with WidgetsBindingObserver {
  late VillageTime _currentTime;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    _currentTime = VillageTimeService.getCurrentTime();

    _timer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _updateTime(),
    );
  }

  void _updateTime() {
    final newTime = VillageTimeService.getCurrentTime();

    if (newTime != _currentTime && mounted) {
      setState(() {
        _currentTime = newTime;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateTime();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = VillageTimeService.imageFor(_currentTime);

    return SizedBox.expand(
      child: AnimatedSwitcher(
        duration: const Duration(seconds: 2),
        child: Image.asset(
          image,
          key: ValueKey(image),
          fit: BoxFit.cover,
          gaplessPlayback: true,
        ),
      ),
    );
  }
}
