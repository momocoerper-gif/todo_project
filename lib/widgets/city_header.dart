
import 'package:flutter/material.dart';

class CityHeader extends StatelessWidget {
  final String? title;
  final double height;

  const CityHeader({
    super.key,
    this.title,
    this.height = 160,
  });

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    final imagePath = isDark
        ? 'assets/images/city_night.png'
        : 'assets/images/city_day.png';

    return SizedBox(
      width: double.infinity,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            imagePath,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.none,
          ),

          // Leichte Abdunklung für lesbaren Text
          if (title != null)
            Container(
              color: Colors.black.withValues(alpha: 0.25),
            ),

          if (title != null)
            Positioned(
              left: 20,
              bottom: 16,
              right: 20,
              child: Text(
                title!,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: const [
                        Shadow(
                          blurRadius: 5,
                          color: Colors.black,
                        ),
                      ],
                    ),
              ),
            ),
        ],
      ),
    );
  }
}
