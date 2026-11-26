import 'package:flutter/material.dart';
import 'core/models/child_profile.dart';
import 'core/models/daily_usage_state.dart';
import 'core/platform/device_lock_service.dart';
import 'core/services/audio_guide_service.dart';
import 'core/services/curriculum_service.dart';
import 'core/services/escalation_engine.dart';
import 'core/services/storage_service.dart';
import 'features/lock_screen/lock_screen.dart';
import 'features/parent/parent_dashboard_screen.dart';
import 'features/parent/parent_gate_dialog.dart';
import 'features/quiz/quiz_screen.dart';

void main() {
  runApp(const LockWillApp());
}

class LockWillApp extends StatelessWidget {
  const LockWillApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LockWill',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF8C42)),
        useMaterial3: true,
      ),
      home: const LockWillHomeController(),
    );
  }
}

class LockWillHomeController extends StatefulWidget {
  const LockWillHomeController({super.key});

  @override
  State<LockWillHomeController> createState() => _LockWillHomeControllerState();
}

class _LockWillHomeControllerState extends State<LockWillHomeController> {
  final DeviceLockService _lockService = MethodChannelDeviceLockService();
  final EscalationEngine _escalationEngine = EscalationEngine();
  final CurriculumService _curriculumService = CurriculumService();
  final AudioGuideService _audioGuide = AudioGuideService();
  final StorageService _storage = StorageService();

  bool _loaded = false;
  late ChildProfile _profile;
  late DailyUsageState _usageState;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final profile = await _storage.loadProfile();
    await _audioGuide.applyProfileSettings(profile);
    var usage = await _storage.loadUsageState(profile);
    final fresh = _escalationEngine.ensureFreshDay(usage, profile);
    if (fresh.dateKey != usage.dateKey) {
      _curriculumService.resetSessionHistory();
      await _storage.saveUsageState(fresh);
      usage = fresh;
    }
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _usageState = usage;
      _loaded = true;
    });
  }

  Future<void> _startExtensionQuiz() async {
    _usageState = _escalationEngine.ensureFreshDay(_usageState, _profile);
    final challenge = _escalationEngine.nextChallenge(_usageState, _profile);
    if (challenge.isDailyCapReached) return;

    final questions = await _curriculumService.loadQuestionsForChallenge(
      profile: _profile,
      targetDifficulty: challenge.targetDifficulty,
      count: challenge.questionCount,
    );

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          profile: _profile,
          challenge: challenge,
          questions: questions,
          audioGuide: _audioGuide,
          onCompleted: (correctCount) async {
            Navigator.of(context).pop();
            await _audioGuide.playUnlockSound();
            await _lockService.unlockForMinutes(challenge.rewardMinutes);
            final updated = _usageState.copyWith(
              grantedMinutes:
                  _usageState.grantedMinutes + challenge.rewardMinutes,
              extensionCountToday: _usageState.extensionCountToday + 1,
              totalCorrectToday: _usageState.totalCorrectToday + correctCount,
            );
            await _storage.saveUsageState(updated);
            setState(() => _usageState = updated);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Chúc mừng ${_profile.name}! Bé đã nhận thêm +${challenge.rewardMinutes} phút!',
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Future<void> _openParentDashboard() async {
    final verified = await showDialog<bool>(
      context: context,
      builder: (_) => ParentGateDialog(expectedPin: _profile.parentPin),
    );
    if (verified != true || !mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ParentDashboardScreen(
          profile: _profile,
          usageState: _usageState,
          audioGuide: _audioGuide,
          onSaveProfile: (updated) async {
            await _storage.saveProfile(updated);
            await _audioGuide.applyProfileSettings(updated);
            _curriculumService.resetSessionHistory();
            setState(() => _profile = updated);
            await _lockService.startMonitoring(updated.blockedPackages);
          },
          onSimulateTimeUp: () async {
            final updated = _usageState.copyWith(
              usedMinutes: _usageState.grantedMinutes,
            );
            await _storage.saveUsageState(updated);
            setState(() => _usageState = updated);
            if (mounted) Navigator.of(context).pop();
          },
          onRequestPermissions: () => _lockService.requestRequiredPermissions(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFF8EE),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    _usageState = _escalationEngine.ensureFreshDay(_usageState, _profile);
    final challenge = _escalationEngine.nextChallenge(_usageState, _profile);

    return LockScreen(
      profile: _profile,
      usageState: _usageState,
      nextChallenge: challenge,
      isMuted: _audioGuide.isMuted,
      onToggleMute: () {
        setState(() {
          _audioGuide.isMuted = !_audioGuide.isMuted;
        });
        if (_audioGuide.isMuted) _audioGuide.stop();
      },
      onStartQuiz: _startExtensionQuiz,
      onOpenParentGate: _openParentDashboard,
      onSpeakWelcome: () => _audioGuide.speak(
        'Chào ${_profile.name}! Hết giờ giải trí rồi. Bé hãy bấm nút màu cam để làm ${challenge.questionCount} câu hỏi nhận thêm ${challenge.rewardMinutes} phút nhé!',
      ),
    );
  }
}
