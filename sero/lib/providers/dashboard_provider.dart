import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dashboard_stats.dart';
import '../models/society_vitals.dart';
import '../services/api_service.dart';

final dashboardProvider = AsyncNotifierProvider<DashboardNotifier, DashboardStats>(() {
  return DashboardNotifier();
});

class DashboardNotifier extends AsyncNotifier<DashboardStats> {
  @override
  Future<DashboardStats> build() async {
    return _fetchStats();
  }

  Future<DashboardStats> _fetchStats() async {
    try {
      final response = await ApiService.get('/admin/dashboard-stats');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return DashboardStats.fromJson(data);
      } else {
        throw Exception('Failed to load dashboard stats: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchStats());
  }
}

final societyVitalsProvider = StreamProvider<SocietyVitals>((ref) {
  return FirebaseFirestore.instance
      .collection('societies')
      .doc('main_society')
      .collection('vitals')
      .doc('current')
      .snapshots()
      .map((snap) {
        if (!snap.exists) {
          return SocietyVitals(
            parcelsPending: 0,
            guardsOnDuty: 0,
            activeMaintenance: "None",
            systemStatus: "Stable",
            lastUpdate: DateTime.now(),
          );
        }
        return SocietyVitals.fromMap(snap.data()!);
      });
});
