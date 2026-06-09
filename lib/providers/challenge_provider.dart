import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/challenge.dart';
import '../models/message.dart';
import '../services/api_service.dart';
import '../utils/logger.dart';

class ChallengeProvider extends ChangeNotifier {
  List<Challenge> _challenges = [];
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  List<Challenge> get challenges => _challenges;
  bool get isLoading => _isLoading;

  Future<void> fetchChallenges() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.dio.get('/challenges');
      _challenges = (response.data as List).map((c) => Challenge.fromJson(c)).toList();
    } catch (e) {
      AppLogger.error('Error fetching challenges', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Challenge>> fetchSharedChallenges(String friendId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.dio.get('/challenges/shared/$friendId');
      return (response.data as List).map((c) => Challenge.fromJson(c)).toList();
    } catch (e) {
      AppLogger.error('Error fetching shared challenges', e);
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createChallenge(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.dio.post('/challenges', data: data);
      await fetchChallenges();
      return true;
    } catch (e) {
      AppLogger.error('Error creating challenge', e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitProof(String challengeId, {
    String? proofText,
    String? proofType,
    File? file,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      FormData formData = FormData.fromMap({
        'challengeId': challengeId,
        if (proofText != null) 'proofText': proofText,
        if (proofType != null) 'proofType': proofType,
        if (file != null)
          'file': await MultipartFile.fromFile(
            file.path,
            filename: file.path.split('/').last,
          ),
      });

      await _apiService.dio.post('/challenges/submit', data: formData);
      await fetchChallenges();
      return true;
    } catch (e) {
      AppLogger.error('Error submitting proof', e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> fetchSubmission(String challengeId) async {
    try {
      final response = await _apiService.dio.get('/challenges/$challengeId/submission');
      return response.data;
    } catch (e) {
      AppLogger.error('Error fetching submission', e);
      return null;
    }
  }

  Future<bool> reviewSubmission(String submissionId, String status) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.dio.post('/challenges/review', data: {
        'submissionId': submissionId,
        'status': status,
      });
      await fetchChallenges();
      return true;
    } catch (e) {
      AppLogger.error('Error reviewing submission', e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Discussion / Messages
  final Map<String, List<Message>> _challengeMessages = {};
  Map<String, List<Message>> get challengeMessages => _challengeMessages;

  Future<void> fetchMessages(String challengeId) async {
    try {
      final response = await _apiService.dio.get('/challenges/$challengeId/messages');
      _challengeMessages[challengeId] = (response.data as List).map((m) => Message.fromJson(m)).toList();
      notifyListeners();
    } catch (e) {
      AppLogger.error('Error fetching messages', e);
    }
  }

  Future<bool> sendMessage(String challengeId, String content) async {
    try {
      final response = await _apiService.dio.post('/challenges/$challengeId/messages', data: {'content': content});
      final newMessage = Message.fromJson(response.data);
      if (_challengeMessages[challengeId] != null) {
        _challengeMessages[challengeId]!.add(newMessage);
      } else {
        _challengeMessages[challengeId] = [newMessage];
      }
      notifyListeners();
      return true;
    } catch (e) {
      AppLogger.error('Error sending message', e);
      return false;
    }
  }
}
