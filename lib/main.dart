import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'core/models/child_profile.dart';
import 'core/models/daily_usage_state.dart';
import 'core/models/owl_pet_state.dart';
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
import 'features/pet/owl_home_screen.dart';
import 'features/quiz/celebration_dialog.dart';
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
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: mq.textScaler.clamp(
              minScaleFactor: 0.85,
              maxScaleFactor: 1.25,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const LockWillHomeController(),
    );
  }
}

class LockWillHomeController extends StatefulWidget {
  const LockWillHomeController({super.key});

  @override
  State<LockWillHomeController> createState() => _LockWillHomeControllerState();
}

class _LockWillHomeControllerState extends State<LockWillHomeController>
    with WidgetsBindingObserver {
  final DeviceLockService _lockService = MethodChannelDeviceLockService();
  final EscalationEngine _escalationEngine = EscalationEngine();
  final CurriculumService _curriculumService = CurriculumService();
  final AudioGuideService _audioGuide = AudioGuideService();
  final StorageService _storage = StorageService();
  final LearningReportService _reportService = LearningReportService();

  bool _loaded = false;
  bool _needsOnboarding = false;
  late ChildProfile _profile;
  late OwlPetState _petState;
  late DailyUsageState _usageState;
  int _remainingSeconds = 0;
  List<InstalledAppInfo> _unlockedApps = const [];
  Timer? _syncTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _syncTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _loaded) {
      _refreshRemainingSeconds();
      _reportService.flushPendingQueue(
        profile: _profile,
        deviceLockService: _lockService,
      );
    }
  }

  Future<void> _initData() async {
    final onboarded = await _storage.hasCompletedOnboarding();
    final profile = await _storage.loadProfile();
    final pet = await _storage.loadPetState();
    await _audioGuide.applyProfileSettings(profile);
    await _audioGuide.setBgmEnabled(profile.bgmEnabled);
    _curriculumService.syncQuestionsFromGitHub(profile.githubRepo);

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
      // Sang ngày mới tự động nạp quỹ miễn phí đầu ngày xuống Android Native.
      if (profile.dailyBaseMinutes > 0) {
        await _lockService.unlockForMinutes(profile.dailyBaseMinutes);
      }
    }

    final rem = await _lockService.getRemainingUnlockSeconds();
    final apps = await _resolveBlockedAppInfos(profile.blockedPackages);

    // Tự động đẩy bù các phiên học lưu offline lên GitHub nếu đã có mạng.
    _reportService.flushPendingQueue(
      profile: profile,
      deviceLockService: _lockService,
    );

    if (!mounted) return;
    setState(() {
      _profile = profile;
      _petState = pet;
      _usageState = usage;
      _remainingSeconds = rem;
      _unlockedApps = apps;
      _needsOnboarding = !onboarded;
      _loaded = true;
    });

    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _refreshRemainingSeconds();
    });
  }

  Future<void> _refreshRemainingSeconds() async {
    if (!mounted || !_loaded) return;
    if (kIsWeb) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds = (_remainingSeconds - 2).clamp(0, 86400);
        });
      }
      return;
    }
    final rem = await _lockService.getRemainingUnlockSeconds();
    if (mounted && rem != _remainingSeconds) {
      setState(() => _remainingSeconds = rem);
    }
  }

  Future<List<InstalledAppInfo>> _resolveBlockedAppInfos(
      List<String> packages) async {
    final installed = await _lockService.getInstalledApps();
    final byPkg = {for (final a in installed) a.packageName: a};
    return packages.map((pkg) {
      final found = byPkg[pkg];
      if (found != null) return found;
      final fallbackName = pkg.contains('youtube')
          ? 'YouTube'
          : (pkg.contains('tiktok') ||
                  pkg.contains('trill') ||
                  pkg.contains('musically')
              ? 'TikTok'
              : pkg.split('.').last);
      return InstalledAppInfo(packageName: pkg, appName: fallbackName);
    }).toList();
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
          petState: _petState,
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
            final updatedPet = _petState
                .copyWith(happiness: _petState.happiness + 12)
                .addXp(summary.totalQuestions * 4);
            await _storage.saveProfile(updatedProfile);
            await _storage.savePetState(updatedPet);
            await _storage.saveUsageState(updated);

            final nextRem = kIsWeb
                ? _remainingSeconds + challenge.rewardMinutes * 60
                : await _lockService.getRemainingUnlockSeconds();

            setState(() {
              _profile = updatedProfile;
              _petState = updatedPet;
              _usageState = updated;
              _remainingSeconds = nextRem > 0
                  ? nextRem
                  : challenge.rewardMinutes * 60;
            });

            // Lưu & tự đồng bộ báo cáo học tập + lịch sử sử dụng máy lên GitHub (kèm Offline Queue).
            _reportService.recordAndSyncSession(
              profile: updatedProfile,
              deviceLockService: _lockService,
              totalQuestions: summary.totalQuestions,
              firstTryCorrect: summary.firstTryCorrect,
              wrongAttempts: summary.wrongAttempts,
              rewardMinutes: challenge.rewardMinutes,
              subjectBreakdown: summary.subjectBreakdown,
            );

            _audioGuide.speak(
              'Chúc mừng ${updatedProfile.name}! Con thật xuất sắc, đã được thưởng thêm ${challenge.rewardMinutes} phút và mở khóa ứng dụng giải trí rồi!',
            );

            if (mounted) {
              await showDialog<void>(
                context: context,
                barrierDismissible: true,
                builder: (_) => CelebrationDialog(
                  childName: updatedProfile.name,
                  petState: updatedPet,
                  rewardMinutes: challenge.rewardMinutes,
                  earnedStars: earnedStars,
                  unlockedApps: _unlockedApps,
                  onLaunchApp: (pkg) => _lockService.launchApp(pkg),
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
            final apps = await _resolveBlockedAppInfos(updated.blockedPackages);
            setState(() {
              _profile = updated;
              _unlockedApps = apps;
            });
            await _lockService.startMonitoring(updated.blockedPackages);
          },
          onSimulateTimeUp: () async {
            await _lockService.lockDeviceApps();
            final updated = _usageState.copyWith(
              usedMinutes: _usageState.grantedMinutes,
            );
            await _storage.saveUsageState(updated);
            setState(() {
              _usageState = updated;
              _remainingSeconds = 0;
            });
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

  Future<void> _openOwlHome() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OwlHomeScreen(
          profile: _profile,
          petState: _petState,
          audioGuide: _audioGuide,
          onUpdateState: (updatedProfile, updatedPet) async {
            await _storage.saveProfile(updatedProfile);
            await _storage.savePetState(updatedPet);
            if (!mounted) return;
            setState(() {
              _profile = updatedProfile;
              _petState = updatedPet;
            });
          },
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

    if (_needsOnboarding) {
      return OnboardingScreen(
        initialProfile: _profile,
        onCompleted: (configuredProfile) async {
          await _storage.saveProfile(configuredProfile);
          await _storage.markOnboardingCompleted();
          await _audioGuide.applyProfileSettings(configuredProfile);
          _curriculumService.resetSessionHistory();
          final apps =
              await _resolveBlockedAppInfos(configuredProfile.blockedPackages);
          setState(() {
            _profile = configuredProfile;
            _unlockedApps = apps;
            _needsOnboarding = false;
          });
        },
      );
    }

    _usageState = _escalationEngine.ensureFreshDay(_usageState, _profile);
    final challenge = _escalationEngine.nextChallenge(_usageState, _profile);

    return LockScreen(
      profile: _profile,
      petState: _petState,
      usageState: _usageState,
      nextChallenge: challenge,
      remainingSeconds: _remainingSeconds,
      unlockedApps: _unlockedApps,
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
      onOpenOwlHome: _openOwlHome,
      onLaunchApp: (pkg) => _lockService.launchApp(pkg),
      onStartQuiz: _startExtensionQuiz,
      onOpenParentGate: _openParentDashboard,
      onSpeakWelcome: () => _audioGuide.speak(
        'Chào ${_profile.name}! Hết giờ giải trí rồi. Bé hãy bấm nút màu cam để làm ${challenge.questionCount} câu hỏi nhận thêm ${challenge.rewardMinutes} phút nhé!',
      ),
    );
  }
}
