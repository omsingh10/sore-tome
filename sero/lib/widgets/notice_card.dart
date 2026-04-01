import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../models/notice.dart';

class NoticeCard extends StatelessWidget {
  final Notice notice;

  const NoticeCard({super.key, required this.notice});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    notice.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _NoticeBadge(tag: notice.tag),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              notice.body,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B6B6B)),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoticeBadge extends StatelessWidget {
  final String tag;
  const _NoticeBadge({required this.tag});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (tag) {
      case 'new':
        bg = kBadgeGreenBg;
        fg = kBadgeGreenText;
        label = 'New';
        break;
      case 'today':
        bg = kBadgeAmberBg;
        fg = kBadgeAmberText;
        label = 'Today';
        break;
      default:
        bg = kBadgeBlueBg;
        fg = kBadgeBlueText;
        label = 'Info';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: fg),
      ),
    );
  }
}
