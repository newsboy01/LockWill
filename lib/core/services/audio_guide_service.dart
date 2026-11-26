import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/child_profile.dart';

class VoiceOption {
  const VoiceOption({
    required this.name,
    required this.locale,
    required this.label,
  });

  final String name;
  final String locale;
  final String label;
}

/// Dịch vụ phát âm thanh hiệu ứng (.wav) và giọng đọc hướng dẫn (TTS tiếng Việt tùy chỉnh).
class AudioGuideService {
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _bgmPlayer = AudioPlayer();

  bool _initialized = false;
  bool isMuted = false;
  bool bgmEnabled = false;
  double _speechRate = 0.45;
  double _speechPitch = 1.08;
  String _voiceName = '';
  SfxStyle _sfxStyle = SfxStyle.cheerful;

  Future<void> init() async {
    if (_initialized) return;
    await _tts.setLanguage('vi-VN');
    await _tts.setSpeechRate(_speechRate);
    await _tts.setPitch(_speechPitch);
    _initialized = true;
  }

  /// Đồng bộ cài đặt giọng đọc từ hồ sơ phụ huynh đã chỉnh.
  Future<void> applyProfileSettings(ChildProfile profile) async {
    _speechRate = profile.speechRate.clamp(0.25, 0.75);
    _speechPitch = profile.speechPitch.clamp(0.8, 1.3);
    _voiceName = profile.voiceName;
    _sfxStyle = profile.sfxStyle;

    await init();
    await _tts.setLanguage('vi-VN');
    await _tts.setSpeechRate(_speechRate);
    await _tts.setPitch(_speechPitch);

    if (_voiceName.isNotEmpty) {
      try {
        await _tts.setVoice({'name': _voiceName, 'locale': 'vi-VN'});
      } catch (_) {
        // Fallback giữ nguyên giọng vi-VN mặc định của thiết bị.
      }
    }
  }

  /// Lấy danh sách giọng tiếng Việt có sẵn trên điện thoại / trình duyệt.
  Future<List<VoiceOption>> getVietnameseVoices() async {
    await init();
    try {
      final rawVoices = await _tts.getVoices;
      if (rawVoices is! List) return const [];
      final result = <VoiceOption>[];
      for (final item in rawVoices) {
        if (item is Map) {
          final name = (item['name'] ?? '').toString();
          final locale = (item['locale'] ?? '').toString();
          if (locale.toLowerCase().startsWith('vi') && name.isNotEmpty) {
            result.add(
              VoiceOption(
                name: name,
                locale: locale,
                label: '$name ($locale)',
              ),
            );
          }
        }
      }
      return result;
    } catch (_) {
      return const [];
    }
  }

  Future<void> speak(String text) async {
    if (isMuted || text.trim().isEmpty) return;
    await init();
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> testVoice({
    required double rate,
    required double pitch,
    required String voiceName,
    required String sampleText,
  }) async {
    await init();
    await _tts.stop();
    await _tts.setLanguage('vi-VN');
    await _tts.setSpeechRate(rate.clamp(0.25, 0.75));
    await _tts.setPitch(pitch.clamp(0.8, 1.3));
    if (voiceName.isNotEmpty) {
      try {
        await _tts.setVoice({'name': voiceName, 'locale': 'vi-VN'});
      } catch (_) {}
    }
    await _tts.speak(sampleText);
  }

  Future<void> playCorrectSound() async {
    if (isMuted || _sfxStyle == SfxStyle.off) return;
    await _sfxPlayer.stop();
    await _sfxPlayer.setVolume(_sfxStyle == SfxStyle.gentle ? 0.45 : 1.0);
    await _sfxPlayer.play(AssetSource('audio/correct.wav'));
  }

  Future<void> playWrongSound() async {
    if (isMuted || _sfxStyle == SfxStyle.off) return;
    await _sfxPlayer.stop();
    await _sfxPlayer.setVolume(_sfxStyle == SfxStyle.gentle ? 0.35 : 0.85);
    await _sfxPlayer.play(AssetSource('audio/wrong.wav'));
  }

  Future<void> playUnlockSound() async {
    if (isMuted || _sfxStyle == SfxStyle.off) return;
    await _sfxPlayer.stop();
    await _sfxPlayer.setVolume(_sfxStyle == SfxStyle.gentle ? 0.5 : 1.0);
    await _sfxPlayer.play(AssetSource('audio/unlock.wav'));
  }

  Future<void> setBgmEnabled(bool enabled) async {
    bgmEnabled = enabled;
    if (enabled && !isMuted) {
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.setVolume(0.22);
      await _bgmPlayer.play(AssetSource('audio/bgm_gentle.wav'));
    } else {
      await _bgmPlayer.stop();
    }
  }

  Future<void> stop() async {
    await _tts.stop();
    await _sfxPlayer.stop();
    await _bgmPlayer.stop();
  }
}
