import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum TtsState { playing, stopped, paused, continued }

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  
  TtsState _ttsState = TtsState.stopped;
  TtsState get ttsState => _ttsState;

  // Configuration variables
  double _speed = 1.0;
  double _pitch = 1.0;
  String _language = 'en-US'; // default
  Map<String, String>? _currentVoice;

  // Active word-highlight tracking streams
  final StreamController<Map<String, dynamic>> _progressStreamController = 
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get progressStream => _progressStreamController.stream;

  final StreamController<TtsState> _stateStreamController = 
      StreamController<TtsState>.broadcast();
  Stream<TtsState> get stateStream => _stateStreamController.stream;

  TtsService() {
    _initTts();
  }

  void _initTts() {
    _flutterTts.setStartHandler(() {
      _ttsState = TtsState.playing;
      _stateStreamController.add(TtsState.playing);
    });

    _flutterTts.setCompletionHandler(() {
      _ttsState = TtsState.stopped;
      _stateStreamController.add(TtsState.stopped);
    });

    _flutterTts.setPauseHandler(() {
      _ttsState = TtsState.paused;
      _stateStreamController.add(TtsState.paused);
    });

    _flutterTts.setContinueHandler(() {
      _ttsState = TtsState.playing;
      _stateStreamController.add(TtsState.playing);
    });

    _flutterTts.setErrorHandler((msg) {
      debugPrint("TTS Error: $msg");
      _ttsState = TtsState.stopped;
      _stateStreamController.add(TtsState.stopped);
    });

    // Native word progress tracker (highlights active text)
    _flutterTts.setProgressHandler((String text, int startOffset, int endOffset, String word) {
      _progressStreamController.add({
        'text': text,
        'start': startOffset,
        'end': endOffset,
        'word': word,
      });
    });
  }

  Future<List<Map<String, String>>> getAvailableVoices() async {
    try {
      final List<dynamic> voices = await _flutterTts.getVoices;
      return voices.map((v) => Map<String, String>.from(v as Map)).toList();
    } catch (e) {
      debugPrint("Error fetching voices: $e");
      return [];
    }
  }

  Future<void> setLanguage(String languageCode) async {
    _language = languageCode;
    await _flutterTts.setLanguage(languageCode);
  }

  Future<void> setSpeed(double speed) async {
    _speed = speed;
    await _flutterTts.setSpeechRate(speed * 0.5); // Normalize speed multiplier for flutter_tts (typically 0.0 to 1.0)
  }

  Future<void> setPitch(double pitch) async {
    _pitch = pitch;
    await _flutterTts.setPitch(pitch);
  }

  Future<void> setVoice(Map<String, String> voice) async {
    _currentVoice = voice;
    await _flutterTts.setVoice(voice);
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    
    // Configure before speaking
    await _flutterTts.setLanguage(_language);
    await _flutterTts.setSpeechRate(_speed * 0.5);
    await _flutterTts.setPitch(_pitch);
    
    if (_currentVoice != null) {
      await _flutterTts.setVoice(_currentVoice!);
    }

    await _flutterTts.speak(text);
  }

  Future<void> pause() async {
    await _flutterTts.pause();
    _ttsState = TtsState.paused;
    _stateStreamController.add(TtsState.paused);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
    _ttsState = TtsState.stopped;
    _stateStreamController.add(TtsState.stopped);
  }

  void dispose() {
    _progressStreamController.close();
    _stateStreamController.close();
  }
}
