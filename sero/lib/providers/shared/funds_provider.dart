import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/services/api_service.dart';
import 'package:sero/models/fund.dart';
import 'package:sero/providers/shared/auth_provider.dart';

final fundsProvider = StateNotifierProvider<FundsNotifier, AsyncValue<List<FundTransaction>>>((ref) {
  return FundsNotifier(ref);
});

final fundSummaryProvider = FutureProvider<FundSummary>((ref) async {
  try {
    final res = await ApiService.get('/funds/summary');
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return FundSummary(
        totalCollected: (data['totalCollected'] ?? 0).toDouble(),
        totalSpent: (data['totalSpent'] ?? 0).toDouble(),
        outstandingDues: (data['outstandingDues'] ?? 0).toDouble(),
        overdueCount: (data['overdueCount'] ?? 0).toInt(),
        categoryBreakdown: (data['categoryBreakdown'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ),
        topExpenseCategories: data['topCategories'] ?? 'None',
      );
    }
  } catch (e) {
    // Return empty summary on error to prevent UI crash
  }
  return FundSummary(totalCollected: 0, totalSpent: 0);
});

final overdueResidentsProvider = FutureProvider<List<OverdueResident>>((ref) async {
  final res = await ApiService.get('/funds/maintenance-status');
  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);
    return (data['unpaid'] as List).map((x) => OverdueResident.fromMap(x)).toList();
  }
  return [];
});

final residentBalanceProvider = FutureProvider<double>((ref) async {
  final user = ref.watch(authProvider).value;
  if (user == null) return 0.0;
  
  try {
    final res = await ApiService.get('/funds/maintenance-status');
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final list = data['unpaid'] as List;
      final myEntry = list.firstWhere(
        (x) => x['name'] == user.name, // Simplified matching by name
        orElse: () => null,
      );
      return myEntry != null ? (myEntry['amount'] as num).toDouble() : 0.0;
    }
  } catch (e) {
    // Silent fail
  }
  return 0.0;
});

class FundsNotifier extends StateNotifier<AsyncValue<List<FundTransaction>>> {
  final Ref ref;
  FundsNotifier(this.ref) : super(const AsyncValue.loading()) {
    fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    state = const AsyncValue.loading();
    try {
      final res = await ApiService.get('/funds/transactions');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data['transactions'] as List).map((x) {
           return FundTransaction.fromMap(x);
        }).toList();
        state = AsyncValue.data(list);
      } else {
        throw jsonDecode(res.body)['error'] ?? 'Failed to fetch funds';
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addTransaction(FundTransaction tx) async {
    try {
      final res = await ApiService.post('/funds/transactions', tx.toMap());
      if (res.statusCode == 201) {
        fetchTransactions();
        ref.invalidate(fundSummaryProvider);
        ref.invalidate(overdueResidentsProvider);
      } else {
        throw jsonDecode(res.body)['error'] ?? 'Failed to add transaction';
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateSettings({double? target, String? currency}) async {
    try {
      final res = await ApiService.post('/funds/settings', {
        if (target != null) 'target': target,
        if (currency != null) 'currency': currency,
      });

      if (res.statusCode == 200) {
        // Refresh summary after update
        ref.invalidate(fundSummaryProvider);
      } else {
        throw jsonDecode(res.body)['error'] ?? 'Failed to update settings';
      }
    } catch (e) {
      rethrow;
    }
  }
}




