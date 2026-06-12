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

  int getCompletedTodayCount(String userId) {
    final today = DateTime.now();
    return _challenges.where((c) => 
      c.recipient.id == userId && 
      c.status == 'approved' && 
      c.updatedAt.day == today.day &&
      c.updatedAt.month == today.month &&
      c.updatedAt.year == today.year
    ).length;
  }

  List<Challenge> getRecentFriendActivity(String userId) {
    final activity = _challenges.where((c) => c.recipient.id != userId && c.status != 'pending').toList();
    activity.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return activity.take(5).toList();
  }

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

  Future<String?> uploadAttachment(File file) async {
    try {
      String fileName = file.path.split('/').last;
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
      });
      final response = await _apiService.dio.post('/challenges/upload', data: formData);
      return response.data['url'];
    } catch (e) {
      AppLogger.error('Error uploading attachment', e);
      return null;
    }
  }

  Future<bool> submitNotes(String challengeId, List<Note> notes) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.dio.post('/challenges/submit', data: {
        'challengeId': challengeId,
        'notes': notes.map((n) => n.toJson()).toList(),
      });
      await fetchChallenges();
      return true;
    } catch (e) {
      AppLogger.error('Error submitting notes', e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> editSubmission(String submissionId, List<Note> notes) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.dio.post('/challenges/edit', data: {
        'submissionId': submissionId,
        'notes': notes.map((n) => n.toJson()).toList(),
      });
      await fetchChallenges();
      return true;
    } catch (e) {
      AppLogger.error('Error editing submission', e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ChallengeSubmission?> fetchSubmission(String challengeId) async {
    try {
      final response = await _apiService.dio.get('/challenges/$challengeId/submission');
      return ChallengeSubmission.fromJson(response.data);
    } catch (e) {
      AppLogger.error('Error fetching submission', e);
      return null;
    }
  }

  Future<List<ChallengeActivity>> fetchActivities(String challengeId) async {
    try {
      final response = await _apiService.dio.get('/challenges/$challengeId/activities');
      return (response.data as List).map((a) => ChallengeActivity.fromJson(a)).toList();
    } catch (e) {
      AppLogger.error('Error fetching activities', e);
      return [];
    }
  }

  Future<bool> reviewSubmission(String submissionId, String status, int versionNumber, {String? reviewerNote}) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.dio.post('/challenges/review', data: {
        'submissionId': submissionId,
        'status': status,
        'versionNumber': versionNumber,
        if (reviewerNote != null) 'reviewerNote': reviewerNote,
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
