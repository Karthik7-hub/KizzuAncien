import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import 'package:kizzu_ancien/utils/logger.dart';
import 'auth_provider.dart';

class TruthDareProvider extends ChangeNotifier {
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  List<dynamic> _truths = [];
  List<dynamic> _dares = [];

  bool get isLoading => _isLoading;
  List<dynamic> get truths => _truths;
  List<dynamic> get dares => _dares;

  Future<void> fetchHistory() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.dio.get('/truth-dare/history');
      _truths = response.data['truths'];
      _dares = response.data['dares'];
    } catch (e) {
      AppLogger.error('Error fetching truth/dare history', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> answerTruth(String truthId, String answer) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.dio.post('/truth-dare/truth/answer', data: {
        'truthId': truthId,
        'answer': answer,
      });
      await fetchHistory();
      return true;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> completeDare(String dareId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.dio.post('/truth-dare/dare/complete', data: {
        'dareId': dareId,
      });
      await fetchHistory();
      return true;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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

  void clear() {
    _truths = [];
    _dares = [];
    _isLoading = false;
    notifyListeners();
  }
}
