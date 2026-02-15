import 'package:flutter/material.dart';

class StarRating extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onRatingChanged;
  final int maxRating;
  final double size;
  final Color activeColor;
  final Color inactiveColor;
  final bool readOnly;

  const StarRating({
    Key? key,
    required this.rating,
    required this.onRatingChanged,
    this.maxRating = 5,
    this.size = 32,
    this.activeColor = const Color(0xFFFB7185),
    this.inactiveColor = const Color(0xFFE5E7EB),
    this.readOnly = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxRating, (index) {
        final starIndex = index + 1;
        return GestureDetector(
          onTap: readOnly ? null : () => onRatingChanged(starIndex),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(horizontal: size * 0.1),
            child: Icon(
              starIndex <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
              size: size,
              color: starIndex <= rating ? activeColor : inactiveColor,
            ),
          ),
        );
      }),
    );
  }
}

class AverageRatingDisplay extends StatelessWidget {
  final double averageRating;
  final int totalRatings;
  final double starSize;

  const AverageRatingDisplay({
    Key? key,
    required this.averageRating,
    required this.totalRatings,
    this.starSize = 18,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (totalRatings == 0) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star_rounded,
          color: const Color(0xFFFB7185),
          size: starSize,
        ),
        const SizedBox(width: 4),
        Text(
          '${averageRating.toStringAsFixed(1)}',
          style: TextStyle(
            fontSize: starSize - 4,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(width: 3),
        Text(
          '($totalRatings)',
          style: TextStyle(
            fontSize: starSize - 5,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }
}
