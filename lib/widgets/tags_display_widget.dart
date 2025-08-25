import 'package:flutter/material.dart';

class TagsDisplayWidget extends StatelessWidget {
  final List<String> tags;
  final double? fontSize;
  final Color? backgroundColor;
  final Color? textColor;

  const TagsDisplayWidget({
    super.key,
    required this.tags,
    this.fontSize = 12,
    this.backgroundColor = const Color(0xFF37B5B6),
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: tags.map((tag) => _buildTagChip(tag)).toList(),
    );
  }

  Widget _buildTagChip(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        tag,
        style: TextStyle(
          fontSize: fontSize,
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
