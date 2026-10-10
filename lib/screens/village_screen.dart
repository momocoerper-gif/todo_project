
import 'dart:async';

import 'package:flutter/material.dart';

import 'home_screen.dart';
import '../services/village_time_service.dart';

class VillageScreen extends StatefulWidget {
  final VoidCallback onOpenTodos;
  final VoidCallback onOpenCalendar;
  final VoidCallback onOpenFinance;

  const VillageScreen({
    super.key,
    required this.onOpenTodos,
    required this.onOpenCalendar,
    required this.onOpenFinance,
  });

  @override
  State<VillageScreen> createState() => _VillageScreenState();
}

class _VillageScreenState extends State<VillageScreen>
    with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();

  late VillageTime _currentTime;
  Timer? _timeTimer;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    _currentTime = VillageTimeService.getCurrentTime();

    _timeTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _updateTime(),
    );
  }

  void _updateTime() {
    final newTime = VillageTimeService.getCurrentTime();

    if (mounted && newTime != _currentTime) {
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
    _timeTimer?.cancel();
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ------------------------------------------
  // QUESTBOOK ÖFFNEN
  // ------------------------------------------

  Future<void> _openQuestbook() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        void navigateTo(VoidCallback callback) {
          Navigator.of(dialogContext).pop();
          callback();
        }

        return Dialog(
          insetPadding: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Kopfzeile des Questbooks
              Container(
                color: const Color(0xFF6D4C35),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.menu_book,
                      color: Color(0xFFFFD78A),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Mein Questbook',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Questbook schließen',
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Bestehender HomeScreen
              Expanded(
                child: HomeScreen(
                  onOpenTodos: () => navigateTo(
                    widget.onOpenTodos,
                  ),
                  onOpenCalendar: () => navigateTo(
                    widget.onOpenCalendar,
                  ),
                  onOpenFinance: () => navigateTo(
                    widget.onOpenFinance,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ------------------------------------------
  // QUESTBOOK BUTTON
  // ------------------------------------------

  Widget _buildQuestbookButton() {
    return Material(
      elevation: 5,
      color: const Color(0xFF6D4C35),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: _openQuestbook,
        borderRadius: BorderRadius.circular(14),
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Icon(
            Icons.menu_book_rounded,
            color: Color(0xFFFFD78A),
            size: 30,
          ),
        ),
      ),
    );
  }

  // ------------------------------------------
  // DORFPLATZ
  // ------------------------------------------

  @override
  Widget build(BuildContext context) {
    final imagePath = VillageTimeService.imageFor(
      _currentTime,
    );

    return Stack(
      children: [
        // Scrollbare Dorfwelt
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                child: SizedBox(
                  width: constraints.maxWidth,
                  child: Stack(
                    children: [
                      // Tageszeitabhängiges Hintergrundbild
                      AnimatedSwitcher(
                        duration: const Duration(seconds: 2),
                        child: Image.asset(
                          imagePath,
                          key: ValueKey(imagePath),
                          width: constraints.maxWidth,
                          fit: BoxFit.fitWidth,
                          filterQuality: FilterQuality.none,
                        ),
                      ),

                      // Hier werden später unsere
                      // interaktiven Gebäude ergänzt.
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Questbook bleibt beim Scrollen sichtbar
        Positioned(
          top: 16,
          right: 16,
          child: _buildQuestbookButton(),
        ),
      ],
    );
  }
}
