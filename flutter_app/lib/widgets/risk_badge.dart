import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/helpers.dart';

class RiskBadge extends StatelessWidget {
  final String level;
  final bool large;
  const RiskBadge({super.key, required this.level, this.large = false});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.riskColor(level);
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: large ? 14 : 8,
          vertical:   large ? 6  : 3),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(large ? 24 : 12),
        border:       Border.all(color: color.withOpacity(0.6)),
      ),
      child: Text(
        capitalize(level),
        style: TextStyle(
          color:      color,
          fontWeight: FontWeight.w700,
          fontSize:   large ? 14 : 11,
        ),
      ),
    );
  }
}
