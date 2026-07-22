import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_voice_ai/models/user_model.dart';
import 'package:study_voice_ai/services/database_service.dart';

class StatsViewModel extends ChangeNotifier {
  final DatabaseService _dbService;
  
  UserModel? _currentUser;
  
  // Daily breakdown (minutes)
  Map<String, double> _weeklyAnalytics = {
    'Mon': 15.0,
    'Tue': 30.0,
    'Wed': 0.0,
    'Thu': 45.0,
    'Fri': 20.0,
    'Sat': 10.0,
    'Sun': 0.0,
  };

  Timer? _listeningTickTimer;
  int _accumulatedSeconds = 0;

  StatsViewModel({required DatabaseService dbService}) : _dbService = dbService;

  UserModel? get user => _currentUser;
  int get streakDays => _currentUser?.streakDays ?? 0;
  int get totalListeningMinutes => _currentUser?.totalListeningMinutes ?? 0;
  int get totalPdfsUploaded => _currentUser?.totalPdfsUploaded ?? 0;
  Map<String, double> get weeklyAnalytics => _weeklyAnalytics;

  Future<void> initStats(UserModel user) async {
    try {
      _currentUser = user;
      // Try to restore richer saved stats from SharedPreferences for this user
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString('local_user_data_${user.email}');
      if (savedJson != null) {
        try {
          final savedUser = UserModel.fromJson(savedJson);
          // Merge saved stats into current user (keep higher values)
          _currentUser = user.copyWith(
            totalListeningMinutes: savedUser.totalListeningMinutes,
            totalPdfsUploaded: savedUser.totalPdfsUploaded,
            streakDays: savedUser.streakDays,
            lastActiveDate: savedUser.lastActiveDate,
          );
        } catch (_) {}
      }
      await _loadWeeklyAnalytics();
      await checkAndUpdateStreak();
      notifyListeners();
    } catch (e) {
      debugPrint("Warning: Failed to initialize stats: $e");
    }
  }

  Future<void> _loadWeeklyAnalytics() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayKey();
    
    // Load weekly entries from local preferences if present
    for (var day in _weeklyAnalytics.keys) {
      _weeklyAnalytics[day] = prefs.getDouble('weekly_minutes_$day') ?? _weeklyAnalytics[day]!;
    }
  }

  String _getTodayKey() {
    final date = DateTime.now();
    switch (date.weekday) {
      case DateTime.monday: return 'Mon';
      case DateTime.tuesday: return 'Tue';
      case DateTime.wednesday: return 'Wed';
      case DateTime.thursday: return 'Thu';
      case DateTime.friday: return 'Fri';
      case DateTime.saturday: return 'Sat';
      case DateTime.sunday: return 'Sun';
      default: return 'Mon';
    }
  }

  /// Timer triggered while TTS audio plays to record exact listening time
  void startListeningTracker() {
    _listeningTickTimer?.cancel();
    _listeningTickTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _accumulatedSeconds++;
      if (_accumulatedSeconds >= 60) {
        _accumulatedSeconds = 0;
        incrementListeningMinutes(1);
      }
    });
  }

  void stopListeningTracker() {
    _listeningTickTimer?.cancel();
    _accumulatedSeconds = 0;
  }

  Future<void> incrementListeningMinutes(int minutes) async {
    if (_currentUser == null) return;

    final updatedMinutes = _currentUser!.totalListeningMinutes + minutes;
    _currentUser = _currentUser!.copyWith(totalListeningMinutes: updatedMinutes);

    // Update weekly chart map
    final todayKey = _getTodayKey();
    _weeklyAnalytics[todayKey] = (_weeklyAnalytics[todayKey] ?? 0) + minutes;

    // Always persist locally first
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('weekly_minutes_$todayKey', _weeklyAnalytics[todayKey]!);
    await prefs.setString('local_user_data_${_currentUser!.email}', _currentUser!.toJson());
    await prefs.setString('local_user_session', _currentUser!.toJson());

    // Also try cloud DB
    try {
      await _dbService.saveUserStats(_currentUser!);
    } catch (e) {
      debugPrint('Cloud stat save failed (non-fatal): $e');
    }
    notifyListeners();
  }

  Future<void> incrementPdfCount() async {
    if (_currentUser == null) return;
    final updatedCount = _currentUser!.totalPdfsUploaded + 1;
    _currentUser = _currentUser!.copyWith(totalPdfsUploaded: updatedCount);
    // Always persist locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('local_user_data_${_currentUser!.email}', _currentUser!.toJson());
    await prefs.setString('local_user_session', _currentUser!.toJson());
    // Also try cloud DB
    try {
      await _dbService.saveUserStats(_currentUser!);
    } catch (e) {
      debugPrint('Cloud stat save failed (non-fatal): $e');
    }
    notifyListeners();
  }

  /// Calculates study streaks. Checks if user active timestamp was yesterday (increment) or today (retain).
  Future<void> checkAndUpdateStreak() async {
    if (_currentUser == null) return;

    final dateStr = DateTime.now().toIso8601String().substring(0, 10); // YYYY-MM-DD
    final lastActive = _currentUser!.lastActiveDate;

    if (lastActive == dateStr) {
      return; // Already active today, streak safe
    }

    int currentStreak = _currentUser!.streakDays;
    
    if (lastActive.isNotEmpty) {
      final lastDate = DateTime.parse(lastActive);
      final todayDate = DateTime.parse(dateStr);
      final difference = todayDate.difference(lastDate).inDays;

      if (difference == 1) {
        currentStreak++; // Active consecutive day!
      } else if (difference > 1) {
        currentStreak = 1; // Streak broken, restart
      }
    } else {
      currentStreak = 1; // First active day
    }

    _currentUser = _currentUser!.copyWith(
      streakDays: currentStreak,
      lastActiveDate: dateStr,
    );

    await _dbService.saveUserStats(_currentUser!);
    notifyListeners();
  }

  @override
  void dispose() {
    _listeningTickTimer?.cancel();
    super.dispose();
  }
}
