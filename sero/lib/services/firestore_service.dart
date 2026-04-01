import 'dart:convert';
import '../models/notice.dart';
import '../models/issue.dart';
import '../models/fund.dart';
import 'api_service.dart';

class FirestoreService {
  // ---------- NOTICES ----------
  Future<List<Notice>> getNotices() async {
    final res = await ApiService.get('/notices');
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return (data['notices'] as List).map((x) => Notice.fromMap(x)).toList();
    }
    return [];
  }

  Future<void> postNotice(Notice notice) async {
    await ApiService.post('/notices', {
      'title': notice.title,
      'body': notice.body,
      'type': notice.tag,
    });
  }

  // ---------- ISSUES ----------
  Future<List<Issue>> getIssues() async {
    final res = await ApiService.get('/issues');
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return (data['issues'] as List).map((x) => Issue.fromMap(x)).toList();
    }
    return [];
  }

  Future<void> postIssue(Issue issue) async {
    await ApiService.post('/issues', {
      'title': issue.title,
      'description': issue.description,
      'category': 'other',
    });
  }

  Future<void> updateIssueStatus(String issueId, String status) async {
    await ApiService.patch('/issues/$issueId/status', {'status': status});
  }

  // ---------- FUNDS ----------
  Future<FundSummary> getFundSummary() async {
    final res = await ApiService.get('/funds/summary');
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return FundSummary(
        totalCollected: (data['totalCollected'] ?? 0).toDouble(),
        totalSpent: (data['totalSpent'] ?? 0).toDouble(),
      );
    }
    return FundSummary(totalCollected: 0, totalSpent: 0);
  }

  Future<List<FundTransaction>> getTransactions() async {
    final res = await ApiService.get('/funds/transactions');
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return (data['transactions'] as List).map((x) {
         return FundTransaction(
           id: x['id'],
           title: x['title'] ?? '',
           description: x['note'] ?? '',
           amount: x['type'] == 'credit' ? (x['amount'] as num).toDouble() : -1 * (x['amount'] as num).toDouble(),
           date: DateTime.tryParse(x['createdAt'] ?? '') ?? DateTime.now(),
         );
      }).toList();
    }
    return [];
  }

  Future<void> addTransaction(FundTransaction tx) async {
    await ApiService.post('/funds/transactions', {
      'title': tx.title,
      'amount': tx.amount.abs(),
      'type': tx.amount >= 0 ? 'credit' : 'debit',
      'note': tx.description,
    });
  }
}
