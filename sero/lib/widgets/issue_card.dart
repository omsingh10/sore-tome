import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../models/issue.dart';

class IssueCard extends StatelessWidget {
  final Issue issue;
  final bool showResolveButton;
  final VoidCallback? onResolve;

  const IssueCard({
    super.key,
    required this.issue,
    this.showResolveButton = false,
    this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          issue.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatusBadge(status: issue.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Posted by ${issue.postedBy} · ${_timeAgo(issue.createdAt)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B6B6B),
                    ),
                  ),
                ],
              ),
            ),
            if (showResolveButton) ...[
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: onResolve,
                style: OutlinedButton.styleFrom(
                  foregroundColor: kPrimaryGreen,
                  side: const BorderSide(color: kPrimaryGreen, width: 0.5),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(fontSize: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Resolve'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 7) return '${(diff.inDays / 7).round()} week ago';
    if (diff.inDays >= 1) return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    return 'just now';
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'resolved':
        bg = kBadgeGreenBg;
        fg = kBadgeGreenText;
        label = 'Resolved';
        break;
      case 'in_progress':
        bg = kBadgeAmberBg;
        fg = kBadgeAmberText;
        label = 'In progress';
        break;
      default:
        bg = kBadgeRedBg;
        fg = kBadgeRedText;
        label = 'Open';
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
