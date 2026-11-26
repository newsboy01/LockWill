import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Dịch vụ phát âm thanh hiệu ứng (.wav) và giọng đọc hướng dẫn (TTS tiếng Việt).
class AudioGuideService {
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  bool _initialized = false;
  bool isMuted = false;

  Future<void> init() async {
    if (_initialized) return;
    await _tts.setLanguage('vi-VN');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.08);
    _initialized = true;
  }

  Future<void> speak(String text) async {
    if (isMuted || text.trim().isEmpty) return;
    await init();
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> playCorrectSound() async {
    if (isMuted) return;
    await _sfxPlayer.stop();
    await _sfxPlayer.play(AssetSource('audio/correct.wav'));
  }

  Future<void> playWrongSound() async {
    if (isMuted) return;
    await _sfxPlayer.stop();
    await _sfxPlayer.play(AssetSource('audio/wrong.wav'));
  }

  Future<void> playUnlockSound() async {
    if (isMuted) return;
    await _sfxPlayer.stop();
    await _sfxPlayer.play(AssetSource('audio/unlock.wav'));
  }

  Future<void> stop() async {
    await _tts.stop();
    await _sfxPlayer.stop();
  }
}
