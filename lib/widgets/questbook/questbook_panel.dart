
import 'package:flutter/material.dart';

class QuestbookPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const QuestbookPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3DEB2),
        border: Border.all(
          color: const Color(0xFF6B4229),
          width: 4,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            offset: Offset(3, 4),
            blurRadius: 0,
          ),
        ],
      ),
      padding: padding,
      child: DefaultTextStyle.merge(
        style: const TextStyle(
          color: Color(0xFF49301F),
        ),
        child: child,
      ),
    );
  }
}
