import 'package:flutter/material.dart';
import 'dart:convert';
import '../../services/api_client.dart';

class AuditLog {
  final String actionId;
  final String toolId;
  final String userId;
  final String action;
  final String status;
  final String createdAt;
  final String? errorMessage;
  final num? latencyMs;

  AuditLog({
    required this.actionId,
    required this.toolId,
    required this.userId,
    required this.action,
    required this.status,
    required this.createdAt,
    this.errorMessage,
    this.latencyMs,
  });

  factory AuditLog.fromMap(Map<String, dynamic> map) {
    return AuditLog(
      actionId: map['action_id'] ?? '',
      toolId: map['tool_id'] ?? '',
      userId: map['user_id'] ?? '',
      action: map['action'] ?? '',
      status: map['status'] ?? 'unknown',
      createdAt: map['created_at'] ?? '',
      errorMessage: map['error_message'],
      latencyMs: map['latency_ms'],
    );
  }
}

class AuditLogProvider extends ChangeNotifier {
  List<AuditLog> _logs = [];
  bool _isLoading = false;
  bool _hasAnomaly = false;
  String? _anomalyMessage;
  String? _error;

  List<AuditLog> get logs => _logs;
  bool get isLoading => _isLoading;
  bool get hasAnomaly => _hasAnomaly;
  String? get anomalyMessage => _anomalyMessage;
  String? get error => _error;

  Future<void> fetchLogs({int offset = 0, int limit = 50}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await ApiClient.request('GET', '/ai/logs?limit=$limit&offset=$offset');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (offset == 0) {
          _logs = (data['logs'] as List).map((l) => AuditLog.fromMap(l)).toList();
        } else {
          _logs.addAll((data['logs'] as List).map((l) => AuditLog.fromMap(l)));
        }
        _hasAnomaly = data['hasAnomaly'] ?? false;
        _anomalyMessage = data['anomalyMessage'];
      } else {
        final errorData = jsonDecode(res.body);
        _error = errorData['error'] ?? 'Failed to fetch logs';
      }
    } catch (e) {
      _error = 'Network error fetching audit logs';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> exportCsv() async {
    // In a full app, this would trigger a download using url_launcher or dio download.
    // For now we assume the UI provides a button linking directly to the backend stream endpoint.
  }
}
