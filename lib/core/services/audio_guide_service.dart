import 'package:flutter_tts/flutter_tts.dart';

/// Dịch vụ phát giọng đọc hướng dẫn (ưu tiên cho học sinh Lớp 1-2 chưa đọc sõi).
class AudioGuideService {
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;
  bool isMuted = false;

  Future<void> init() async {
    if (_initialized) return;
    await _tts.setLanguage('vi-VN');
    await _tts.setSpeechRate(0.45); // Tốc độ chậm vừa phải cho trẻ nhỏ
    await _tts.setPitch(1.08);
    _initialized = true;
  }

  Future<void> speak(String text) async {
    if (isMuted || text.trim().isEmpty) return;
    await init();
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }
}
