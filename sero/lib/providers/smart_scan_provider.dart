import 'package:flutter/foundation.dart';
import '../../services/ocr_service.dart';

enum SmartScanState { idle, scanning, parsing, confirmation, saving, success, error }

class SmartScanProvider with ChangeNotifier {
  SmartScanState _state = SmartScanState.idle;
  String _errorMessage = "";
  
  // Parsed Data
  Map<String, dynamic>? _extractedData;

  SmartScanState get state => _state;
  String get errorMessage => _errorMessage;
  Map<String, dynamic>? get extractedData => _extractedData;

  /// Trigger the AI Parsing Flow
  Future<void> processReceiptImage(String base64Image) async {
    _state = SmartScanState.parsing;
    _errorMessage = "";
    notifyListeners();

    try {
      final result = await OcrService.extractReceipt(base64Image);
      _extractedData = result;
      _state = SmartScanState.confirmation; // ❗ V5.2 Safety Requirement: Must confirm
    } catch (e) {
      _errorMessage = e.toString();
      _state = SmartScanState.error;
    } finally {
      notifyListeners();
    }
  }

  /// Update individual field during confirmation step
  void updateField(String key, dynamic value) {
    if (_extractedData != null) {
      _extractedData![key] = value;
      notifyListeners();
    }
  }

  /// User confirms the edited/reviewed data and submits
  Future<bool> commitTransaction(Future<void> Function(Map<String, dynamic>) saveCallback) async {
    if (_extractedData == null) return false;

    _state = SmartScanState.saving;
    notifyListeners();

    try {
      await saveCallback(_extractedData!);
      _state = SmartScanState.success;
      return true;
    } catch (e) {
      _errorMessage = 'Failed to save transaction: $e';
      _state = SmartScanState.error;
      return false;
    } finally {
      notifyListeners();
    }
  }

  void reset() {
    _state = SmartScanState.idle;
    _extractedData = null;
    _errorMessage = "";
    notifyListeners();
  }
}
