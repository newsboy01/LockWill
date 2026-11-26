import 'package:flutter/material.dart';
import 'core/models/child_profile.dart';
import 'core/models/daily_usage_state.dart';
import 'core/platform/device_lock_service.dart';
import 'core/services/audio_guide_service.dart';
import 'core/services/curriculum_service.dart';
import 'core/services/escalation_engine.dart';
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

  late ChildProfile _profile;
  late DailyUsageState _usageState;

  @override
  void initState() {
    super.initState();
    _profile = ChildProfile(
      name: 'Bé Minh',
      grade: 1,
      textbook: TextbookSeries.ketNoiTriThuc,
      currentWeek: CurriculumService.estimateCurrentSchoolWeek(),
      dailyBaseMinutes: 30,
      dailyMaxMinutes: 90,
      parentPin: '1234',
    );
    _usageState = DailyUsageState(
      dateKey: EscalationEngine.todayKey(),
      usedMinutes: 30, // Demo trạng thái vừa hết giờ miễn phí đầu ngày
      grantedMinutes: 30,
      extensionCountToday: 0,
      totalCorrectToday: 0,
    );
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
            await _lockService.unlockForMinutes(challenge.rewardMinutes);
            setState(() {
              _usageState = _usageState.copyWith(
                grantedMinutes:
                    _usageState.grantedMinutes + challenge.rewardMinutes,
                extensionCountToday: _usageState.extensionCountToday + 1,
                totalCorrectToday: _usageState.totalCorrectToday + correctCount,
              );
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Chúc mừng! Bé đã nhận thêm +${challenge.rewardMinutes} phút!',
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
          onSaveProfile: (updated) {
            setState(() => _profile = updated);
            _lockService.startMonitoring(updated.blockedPackages);
          },
          onSimulateTimeUp: () {
            setState(() {
              _usageState = _usageState.copyWith(
                usedMinutes: _usageState.grantedMinutes,
              );
            });
            Navigator.of(context).pop();
          },
          onRequestPermissions: () => _lockService.requestRequiredPermissions(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _usageState = _escalationEngine.ensureFreshDay(_usageState, _profile);
    final challenge = _escalationEngine.nextChallenge(_usageState, _profile);

    return LockScreen(
      profile: _profile,
      usageState: _usageState,
      nextChallenge: challenge,
      onStartQuiz: _startExtensionQuiz,
      onOpenParentGate: _openParentDashboard,
      onSpeakWelcome: () => _audioGuide.speak(
        'Chào ${_profile.name}! Hết giờ giải trí rồi. Bé hãy bấm nút màu cam để làm ${challenge.questionCount} câu hỏi nhận thêm ${challenge.rewardMinutes} phút nhé!',
      ),
    );
  }
}
