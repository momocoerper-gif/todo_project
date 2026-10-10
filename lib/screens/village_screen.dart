import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/village_time_service.dart';
import '../widgets/village_background.dart';
import 'home_screen.dart';

/// Village hub. Buildings can be positioned later in the same 941x1672
/// reference coordinate system as the underlying illustration.
class VillageScreen extends StatefulWidget {
  final VoidCallback onOpenTodos;
  final VoidCallback onOpenCalendar;
  final VoidCallback onOpenFinance;
  final VoidCallback onOpenMenu;

  const VillageScreen({
    super.key,
    required this.onOpenTodos,
    required this.onOpenCalendar,
    required this.onOpenFinance,
    required this.onOpenMenu,
  });

  @override
  State<VillageScreen> createState() => _VillageScreenState();
}

class _VillageScreenState extends State<VillageScreen>
    with WidgetsBindingObserver {
  static const double _artWidth = 941;
  static const double _artHeight = 1672;

  final ScrollController _scrollController = ScrollController();
  late VillageTime _currentTime;
  Timer? _timeTimer;
  bool _questbookOpen = false;

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
    final nextTime = VillageTimeService.getCurrentTime();
    if (mounted && nextTime != _currentTime) {
      setState(() => _currentTime = nextTime);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _updateTime();
  }

  Future<void> _openQuestbook() async {
    if (_questbookOpen) return;
    setState(() => _questbookOpen = true);

    try {
      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Questbook schließen',
        barrierColor: Colors.black.withValues(alpha: 0.56),
        transitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (dialogContext, animation, secondaryAnimation) {
          void navigate(VoidCallback target) {
            Navigator.of(dialogContext).pop();
            target();
          }

          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
                  child: Material(
                    color: const Color(0xFF573821),
                    elevation: 16,
                    borderRadius: BorderRadius.circular(13),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        Container(
                          height: 68,
                          padding: const EdgeInsets.symmetric(horizontal: 9),
                          decoration: const BoxDecoration(
                            color: Color(0xFF704526),
                            border: Border(bottom: BorderSide(color: Color(0xFFDBB36B), width: 3)),
                          ),
                          child: Row(
                            children: [
                              Image.asset(
                                'assets/images/questbook/questbook_icon.png',
                                width: 49, height: 49,
                                filterQuality: FilterQuality.none,
                              ),
                              const SizedBox(width: 6),
                              const Expanded(
                                child: Text('Mein Questbook', maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900,
                                    color: Color(0xFFFFE6B0))),
                              ),
                              Semantics(
                                button: true,
                                label: 'Questbook schließen',
                                child: InkWell(
                                  onTap: () => Navigator.of(dialogContext).pop(),
                                  child: Image.asset(
                                    'assets/images/questbook/close_button.png',
                                    width: 51, height: 51,
                                    filterQuality: FilterQuality.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: HomeScreen(
                            onOpenTodos: () => navigate(widget.onOpenTodos),
                            onOpenCalendar: () => navigate(widget.onOpenCalendar),
                            onOpenFinance: () => navigate(widget.onOpenFinance),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
              child: child,
            ),
          );
        },
      );
    } finally {
      if (mounted) setState(() => _questbookOpen = false);
    }
  }

  Widget _controlButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Material(
      elevation: 5,
      color: const Color(0xFF6D4C35),
      borderRadius: BorderRadius.circular(14),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        constraints: const BoxConstraints(minWidth: 52, minHeight: 52),
        icon: Icon(icon, color: const Color(0xFFFFD78A), size: 29),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final worldWidth = constraints.maxWidth;
        final artHeight = worldWidth * (_artHeight / _artWidth);
        final worldHeight = math.max(artHeight, constraints.maxHeight);
        final safeTop = MediaQuery.paddingOf(context).top;

        return Stack(
          fit: StackFit.expand,
          children: [
            // Scroll the whole world; the buttons are *outside* this scroll.
            SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              child: SizedBox(
                width: worldWidth,
                height: worldHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Keep the illustration's aspect ratio. Never crop it.
                    // Short displays get a continuation color below the art.
                    const ColoredBox(color: Color(0xFF577B45)),
                    Positioned(
                      top: 0,
                      left: 0,
                      width: worldWidth,
                      height: artHeight,
                      child: VillageBackground(time: _currentTime),
                    ),
                    // Future buildings: place them at normalized positions
                    // on this world canvas so they scroll with the village.
                  ],
                ),
              ),
            ),
            Positioned(
              top: safeTop + 12,
              left: 16,
              child: _controlButton(
                icon: Icons.menu,
                tooltip: 'Navigation öffnen',
                onPressed: widget.onOpenMenu,
              ),
            ),
            Positioned(
              top: safeTop + 12,
              right: 16,
              child: Semantics(
                label: 'Questbook öffnen', button: true,
                child: Tooltip(
                  message: 'Questbook öffnen',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _questbookOpen ? null : _openQuestbook,
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: Image.asset(
                          'assets/images/questbook/questbook_icon.png',
                          width: 65, height: 65,
                          filterQuality: FilterQuality.none,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _timeTimer?.cancel();
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
