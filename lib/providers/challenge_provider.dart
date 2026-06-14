import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/challenge.dart';
import '../models/message.dart';
import '../models/note.dart';
import '../services/api_service.dart';

import 'package:kizzu_ancien/utils/logger.dart';

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
    List<String>? selectedNotes,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      FormData formData = FormData.fromMap({
        'challengeId': challengeId,
        if (proofText != null) 'proofText': proofText,
        if (proofType != null) 'proofType': proofType,
        if (selectedNotes != null) 'selectedNotes': jsonEncode(selectedNotes),
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

  // Notes
  final Map<String, List<Note>> _challengeNotes = {};
  Map<String, List<Note>> get challengeNotes => _challengeNotes;

  Future<void> fetchNotes(String challengeId) async {
    try {
      final response = await _apiService.dio.get('/challenges/$challengeId/notes');
      final notes = (response.data as List).map((n) => Note.fromJson(n)).toList();
      _challengeNotes[challengeId] = notes;
      notifyListeners();
    } catch (e) {
      AppLogger.error('Error fetching notes', e);
    }
  }

  Future<bool> reorderNotes(String challengeId, List<Note> reorderedNotes) async {
    try {
      final noteOrders = reorderedNotes.asMap().entries.map((entry) {
        return {'id': entry.value.id, 'order': entry.key};
      }).toList();

      await _apiService.dio.put('/challenges/$challengeId/notes/reorder', data: {
        'noteOrders': noteOrders,
      });

      _challengeNotes[challengeId] = reorderedNotes;
      notifyListeners();
      return true;
    } catch (e) {
      AppLogger.error('Error reordering notes', e);
      return false;
    }
  }

  Future<bool> createNote(String challengeId, Map<String, dynamic> noteData, {List<File>? files}) async {
    try {
      final String type = noteData['type'] ?? 'explanation';
      String title = noteData['title'] ?? '';
      
      if (title.trim().isEmpty) {
        final existingNotesOfType = _challengeNotes[challengeId]?.where((n) => n.type.name == type).toList() ?? [];
        final String typeLabel = type[0].toUpperCase() + type.substring(1);
        title = 'Untitled $typeLabel ${existingNotesOfType.length + 1}';
        noteData['title'] = title;
      }

      Response response;
      if (files != null && files.isNotEmpty) {
        final List<MultipartFile> multipartFiles = [];
        for (final file in files) {
          multipartFiles.add(await MultipartFile.fromFile(
            file.path,
            filename: file.path.split('/').last,
          ));
        }

        final formData = FormData.fromMap({
          'title': noteData['title'],
          'description': noteData['description'],
          'type': noteData['type'],
          'content': jsonEncode(noteData['content']),
          'files': multipartFiles,
        });

        response = await _apiService.dio.post(
          '/challenges/$challengeId/notes',
          data: formData,
          options: Options(
            sendTimeout: const Duration(seconds: 60),
            receiveTimeout: const Duration(seconds: 60),
          ),
        );
      } else {
        response = await _apiService.dio.post('/challenges/$challengeId/notes', data: noteData);
      }

      final newNote = Note.fromJson(response.data);
      if (_challengeNotes[challengeId] != null) {
        _challengeNotes[challengeId]!.add(newNote);
      } else {
        _challengeNotes[challengeId] = [newNote];
      }
      notifyListeners();
      return true;
    } catch (e) {
      AppLogger.error('Error creating note', e);
      return false;
    }
  }

  Future<bool> updateNote(String challengeId, String noteId, Map<String, dynamic> noteData, {List<File>? files}) async {
    AppLogger.info('updateNote: challengeId=$challengeId, noteId=$noteId, noteData=$noteData');
    if (challengeId.trim().isEmpty || noteId.trim().isEmpty) {
      AppLogger.error('updateNote failed: challengeId or noteId is empty. challengeId="$challengeId", noteId="$noteId"');
      return false;
    }
    try {
      Response response;
      if (files != null && files.isNotEmpty) {
        final List<MultipartFile> multipartFiles = [];
        for (final file in files) {
          multipartFiles.add(await MultipartFile.fromFile(
            file.path,
            filename: file.path.split('/').last,
          ));
        }

        final formData = FormData.fromMap({
          'title': noteData['title'],
          'description': noteData['description'],
          'content': jsonEncode(noteData['content']),
          'files': multipartFiles,
        });

        response = await _apiService.dio.put(
          '/challenges/$challengeId/notes/$noteId',
          data: formData,
          options: Options(
            sendTimeout: const Duration(seconds: 60),
            receiveTimeout: const Duration(seconds: 60),
          ),
        );
      } else {
        response = await _apiService.dio.put('/challenges/$challengeId/notes/$noteId', data: noteData);
      }

      final updatedNote = Note.fromJson(response.data);
      if (_challengeNotes[challengeId] != null) {
        final index = _challengeNotes[challengeId]!.indexWhere((n) => n.id == noteId);
        if (index != -1) {
          _challengeNotes[challengeId]![index] = updatedNote;
        }
      }
      notifyListeners();
      return true;
    } catch (e) {
      if (e is DioException) {
        AppLogger.error('Error updating note. Response data: ${e.response?.data}', e);
      } else {
        AppLogger.error('Error updating note', e);
      }
      return false;
    }
  }

  Future<bool> deleteNote(String challengeId, String noteId) async {
    if (challengeId.trim().isEmpty || noteId.trim().isEmpty) {
      AppLogger.error('deleteNote failed: challengeId or noteId is empty. challengeId="$challengeId", noteId="$noteId"');
      return false;
    }
    try {
      await _apiService.dio.delete('/challenges/$challengeId/notes/$noteId');
      if (_challengeNotes[challengeId] != null) {
        _challengeNotes[challengeId]!.removeWhere((n) => n.id == noteId);
      }
      notifyListeners();
      return true;
    } catch (e) {
      AppLogger.error('Error deleting note', e);
      return false;
    }
  }

  void clear() {
    _challenges = [];
    _challengeNotes.clear();
    _challengeMessages.clear();
    _isLoading = false;
    notifyListeners();
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
