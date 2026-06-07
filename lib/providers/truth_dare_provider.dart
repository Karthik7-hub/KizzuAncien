import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TruthDareProvider extends ChangeNotifier {
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  bool get isLoading => _isLoading;

  Future<bool> sendTruth(String recipientId, String question) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.dio.post('/truth-dare/truth', data: {
        'recipientId': recipientId,
        'question': question,
      });
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendDare(String recipientId, String task) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.dio.post('/truth-dare/dare', data: {
        'recipientId': recipientId,
        'task': task,
      });
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
