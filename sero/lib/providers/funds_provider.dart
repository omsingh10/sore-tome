import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../models/fund.dart';

final fundsProvider = StateNotifierProvider<FundsNotifier, AsyncValue<List<FundTransaction>>>((ref) {
  return FundsNotifier(ref);
});

final fundSummaryProvider = FutureProvider<FundSummary>((ref) async {
  final res = await ApiService.get('/funds/summary');
  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);
    return FundSummary(
      totalCollected: (data['totalCollected'] ?? 0).toDouble(),
      totalSpent: (data['totalSpent'] ?? 0).toDouble(),
    );
  }
  throw Exception('Failed to fetch summary');
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
           return FundTransaction(
             id: x['id'],
             title: x['title'] ?? '',
             description: x['note'] ?? '',
             amount: x['type'] == 'debit' ? -1 * (x['amount'] as num).toDouble() : (x['amount'] as num).toDouble(),
             date: DateTime.tryParse(x['createdAt'] ?? '') ?? DateTime.now(),
           );
        }).toList();
        state = AsyncValue.data(list);
      } else {
        throw jsonDecode(res.body)['error'] ?? 'Failed to fetch funds';
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
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
