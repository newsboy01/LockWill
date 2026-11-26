import 'package:flutter/material.dart';
import 'core/models/child_profile.dart';
import 'core/models/daily_usage_state.dart';
import 'core/platform/device_lock_service.dart';
import 'core/services/audio_guide_service.dart';
import 'core/services/curriculum_service.dart';
import 'core/services/escalation_engine.dart';
import 'core/services/learning_report_service.dart';
import 'core/services/storage_service.dart';
import 'features/lock_screen/lock_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
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
  final LearningReportService _reportService = LearningReportService();

  bool _loaded = false;
  bool _needsOnboarding = false;
  late ChildProfile _profile;
  late DailyUsageState _usageState;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final onboarded = await _storage.hasCompletedOnboarding();
    final profile = await _storage.loadProfile();
    await _audioGuide.applyProfileSettings(profile);
    await _audioGuide.setBgmEnabled(profile.bgmEnabled);
    // Tự động kiểm tra và cập nhật bộ câu hỏi mới nhất từ GitHub chạy nền.
    _curriculumService.syncQuestionsFromGitHub(profile.githubRepo);

    // Nếu đã cấp quyền Android, tự động kích hoạt dịch vụ giám sát & khóa app ngay khi mở máy.
    final hasPerm = await _lockService.hasRequiredPermissions();
    if (hasPerm && profile.blockedPackages.isNotEmpty) {
      await _lockService.startMonitoring(profile.blockedPackages);
    }

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
      _needsOnboarding = !onboarded;
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
          onCompleted: (summary) async {
            Navigator.of(context).pop();
            await _audioGuide.playUnlockSound();
            await _lockService.unlockForMinutes(challenge.rewardMinutes);

            final updated = _usageState.copyWith(
              grantedMinutes:
                  _usageState.grantedMinutes + challenge.rewardMinutes,
              extensionCountToday: _usageState.extensionCountToday + 1,
              totalCorrectToday:
                  _usageState.totalCorrectToday + summary.firstTryCorrect,
            );
            final earnedStars = summary.firstTryCorrect * 2 + 3;
            final updatedProfile = _profile.copyWith(
              stars: _profile.stars + earnedStars,
            );
            await _storage.saveProfile(updatedProfile);
            await _storage.saveUsageState(updated);
            setState(() {
              _profile = updatedProfile;
              _usageState = updated;
            });

            // Lưu & tự đồng bộ báo cáo học tập + lịch sử sử dụng máy lên GitHub.
            await _reportService.recordAndSyncSession(
              profile: updatedProfile,
              deviceLockService: _lockService,
              totalQuestions: summary.totalQuestions,
              firstTryCorrect: summary.firstTryCorrect,
              wrongAttempts: summary.wrongAttempts,
              rewardMinutes: challenge.rewardMinutes,
              subjectBreakdown: summary.subjectBreakdown,
            );

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Chúc mừng ${_profile.name}! Nhận +${challenge.rewardMinutes} phút & +$earnedStars ⭐!',
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
          deviceLockService: _lockService,
          onSaveProfile: (updated) async {
            await _storage.saveProfile(updated);
            await _audioGuide.applyProfileSettings(updated);
            _curriculumService.resetSessionHistory();
            setState(() => _profile = updated);
            await _lockService.startMonitoring(updated.blockedPackages);
          },
          onSimulateTimeUp: () async {
            await _lockService.lockDeviceApps();
            final updated = _usageState.copyWith(
              usedMinutes: _usageState.grantedMinutes,
            );
            await _storage.saveUsageState(updated);
            setState(() => _usageState = updated);
            if (mounted) Navigator.of(context).pop();
          },
          onRequestPermissions: () => _lockService.requestRequiredPermissions(),
          onSyncQuestionsNow: (repo) =>
              _curriculumService.syncQuestionsFromGitHub(repo),
          onSyncDeviceUsageNow: (repo, token) =>
              _reportService.syncDeviceUsageNow(
            profile: _profile,
            deviceLockService: _lockService,
            overrideRepo: repo,
            overrideToken: token,
          ),
        ),
      ),
    );
  }

  Future<void> _cycleOwlAccessory() async {
    const order = ['grad_cap', 'glasses', 'crown', 'none'];
    final next = order[(order.indexOf(_profile.owlAccessory) + 1) % order.length];
    final updated = _profile.copyWith(owlAccessory: next);
    await _storage.saveProfile(updated);
    setState(() => _profile = updated);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFF8EE),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_needsOnboarding) {
      return OnboardingScreen(
        initialProfile: _profile,
        onCompleted: (configuredProfile) async {
          await _storage.saveProfile(configuredProfile);
          await _storage.markOnboardingCompleted();
          await _audioGuide.applyProfileSettings(configuredProfile);
          _curriculumService.resetSessionHistory();
          setState(() {
            _profile = configuredProfile;
            _needsOnboarding = false;
          });
        },
      );
    }

    _usageState = _escalationEngine.ensureFreshDay(_usageState, _profile);
    final challenge = _escalationEngine.nextChallenge(_usageState, _profile);

    return LockScreen(
      profile: _profile,
      usageState: _usageState,
      nextChallenge: challenge,
      isMuted: _audioGuide.isMuted,
      bgmEnabled: _profile.bgmEnabled,
      onToggleMute: () {
        setState(() {
          _audioGuide.isMuted = !_audioGuide.isMuted;
        });
        if (_audioGuide.isMuted) {
          _audioGuide.stop();
        } else {
          _audioGuide.setBgmEnabled(_profile.bgmEnabled);
        }
      },
      onToggleBgm: () async {
        final next = !_profile.bgmEnabled;
        final updated = _profile.copyWith(bgmEnabled: next);
        await _storage.saveProfile(updated);
        await _audioGuide.setBgmEnabled(next);
        setState(() => _profile = updated);
      },
      onCycleAccessory: _cycleOwlAccessory,
      onStartQuiz: _startExtensionQuiz,
      onOpenParentGate: _openParentDashboard,
      onSpeakWelcome: () => _audioGuide.speak(
        'Chào ${_profile.name}! Hết giờ giải trí rồi. Bé hãy bấm nút màu cam để làm ${challenge.questionCount} câu hỏi nhận thêm ${challenge.rewardMinutes} phút nhé!',
      ),
    );
  }
}
