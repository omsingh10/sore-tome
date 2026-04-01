import '../models/notice.dart';
import '../models/issue.dart';
import '../models/fund.dart';

// Stub: Replace with real Firestore calls
class FirestoreService {
  // ---------- NOTICES ----------
  Future<List<Notice>> getNotices() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      Notice(
        id: '1',
        title: 'Diwali Celebration 🎇',
        body:
            'Oct 31 · Garden area · 7 PM onwards. All residents invited. Snacks will be provided.',
        createdAt: DateTime.now(),
        tag: 'new',
      ),
      Notice(
        id: '2',
        title: 'Water supply off — 10 AM to 1 PM',
        body:
            'Maintenance work on the main overhead tank. Please store water in advance.',
        createdAt: DateTime.now(),
        tag: 'today',
      ),
    ];
  }

  Future<void> postNotice(Notice notice) async {
    // TODO: add to Firestore 'notices' collection
  }

  // ---------- ISSUES ----------
  Future<List<Issue>> getIssues() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      Issue(
        id: '1',
        title: 'Lift not working — Block B',
        description: 'Engineer visit scheduled tomorrow',
        postedBy: 'Rahul',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        status: 'in_progress',
      ),
      Issue(
        id: '2',
        title: 'Stray dogs near parking',
        description: '',
        postedBy: 'Priya',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        status: 'open',
      ),
      Issue(
        id: '3',
        title: 'Street light not working near gate 2',
        description: '',
        postedBy: 'Amit',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        status: 'open',
      ),
      Issue(
        id: '4',
        title: 'Gym equipment repair',
        description: 'Resolved in 2 days',
        postedBy: 'Sneha',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        status: 'resolved',
      ),
      Issue(
        id: '5',
        title: 'Broken gate latch — East entrance',
        description: '',
        postedBy: 'Karan',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        status: 'resolved',
      ),
    ];
  }

  Future<void> postIssue(Issue issue) async {
    // TODO: add to Firestore 'issues' collection
  }

  Future<void> updateIssueStatus(String issueId, String status) async {
    // TODO: update Firestore document
  }

  // ---------- FUNDS ----------
  Future<FundSummary> getFundSummary() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return FundSummary(totalCollected: 240000, totalSpent: 110000);
  }

  Future<List<FundTransaction>> getTransactions() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      FundTransaction(
        id: '1',
        title: 'Lift maintenance',
        description: 'Oct 18',
        amount: -18000,
        date: DateTime.now().subtract(const Duration(days: 13)),
      ),
      FundTransaction(
        id: '2',
        title: 'Maintenance collected',
        description: 'Oct 1 · 80 flats',
        amount: 80000,
        date: DateTime.now().subtract(const Duration(days: 30)),
      ),
      FundTransaction(
        id: '3',
        title: 'Gardening & cleaning',
        description: 'Oct 10',
        amount: -12000,
        date: DateTime.now().subtract(const Duration(days: 21)),
      ),
    ];
  }

  Future<void> addTransaction(FundTransaction tx) async {
    // TODO: add to Firestore 'transactions' collection
  }
}
