import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

class TruthDareProvider extends ChangeNotifier {
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  bool get isLoading => _isLoading;

  Future<bool> sendTruth(BuildContext context, String recipientId, String question) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.dio.post('/truth-dare/truth', data: {
        'recipientId': recipientId,
        'question': question,
      });
      if (context.mounted) {
        await context.read<AuthProvider>().checkAuth();
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendDare(BuildContext context, String recipientId, String task) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.dio.post('/truth-dare/dare', data: {
        'recipientId': recipientId,
        'task': task,
      });
      if (context.mounted) {
        await context.read<AuthProvider>().checkAuth();
      }
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
