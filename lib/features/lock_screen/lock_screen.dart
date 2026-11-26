import 'package:flutter/material.dart';
import '../../core/models/child_profile.dart';
import '../../core/models/daily_usage_state.dart';
import '../../core/platform/device_lock_service.dart';
import '../../core/services/escalation_engine.dart';
import '../../core/ui/responsive_layout.dart';
import '../../core/widgets/animated_owl_mascot.dart';
import '../../core/widgets/tactile_3d_button.dart';

class LockScreen extends StatelessWidget {
  const LockScreen({
    super.key,
    required this.profile,
    required this.usageState,
    required this.nextChallenge,
    required this.remainingSeconds,
    required this.unlockedApps,
    required this.isMuted,
    required this.bgmEnabled,
    required this.onToggleMute,
    required this.onToggleBgm,
    required this.onCycleAccessory,
    required this.onLaunchApp,
    required this.onStartQuiz,
    required this.onOpenParentGate,
    required this.onSpeakWelcome,
  });

  final ChildProfile profile;
  final DailyUsageState usageState;
  final ExtensionChallenge nextChallenge;
  final int remainingSeconds;
  final List<InstalledAppInfo> unlockedApps;
  final bool isMuted;
  final bool bgmEnabled;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleBgm;
  final VoidCallback onCycleAccessory;
  final ValueChanged<String> onLaunchApp;
  final VoidCallback onStartQuiz;
  final VoidCallback onOpenParentGate;
  final VoidCallback onSpeakWelcome;

  bool get isUnlocked => remainingSeconds > 0;

  String _formatClock(int totalSec) {
    final m = totalSec ~/ 60;
    final s = totalSec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  (String, Color) _iconMeta(InstalledAppInfo app) {
    final lower = '${app.appName} ${app.packageName}'.toLowerCase();
    if (lower.contains('youtube')) return ('▶️', const Color(0xFFFF0000));
    if (lower.contains('tiktok') ||
        lower.contains('trill') ||
        lower.contains('musically')) {
      return ('🎵', const Color(0xFF111827));
    }
    if (lower.contains('roblox') || lower.contains('game')) {
      return ('🎮', const Color(0xFF7C3AED));
    }
    if (lower.contains('facebook')) return ('📘', const Color(0xFF1877F2));
    return ('📱', const Color(0xFF0EA5E9));
  }

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveLayout(context);
    final capReached = nextChallenge.isDailyCapReached;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isUnlocked
                ? const [Color(0xFFE6FFF9), Color(0xFFFFFBE6)]
                : const [Color(0xFFFFF3E0), Color(0xFFE8F7FF)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.all(r.pagePadding),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - r.pagePadding * 2,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: r.maxContentWidth),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildTopBar(r),
                          const SizedBox(height: 16),
                          if (r.useSplitLayout)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(child: _buildMascotSection(r)),
                                const SizedBox(width: 28),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _buildInfoSection(r, capReached),
                                      if (isUnlocked) ...[
                                        const SizedBox(height: 14),
                                        _buildUnlockedAppsGrid(r),
                                      ],
                                      const SizedBox(height: 20),
                                      _buildActionButtons(r, capReached),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          else ...[
                            _buildMascotSection(r),
                            SizedBox(height: r.isCompactPhone ? 10 : 16),
                            _buildInfoSection(r, capReached),
                            if (isUnlocked) ...[
                              const SizedBox(height: 14),
                              _buildUnlockedAppsGrid(r),
                            ],
                            SizedBox(height: r.isCompactPhone ? 16 : 22),
                            _buildActionButtons(r, capReached),
                          ],
                          const SizedBox(height: 6),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(ResponsiveLayout r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Text(
                  '🎓 ${profile.name} (${profile.age}t) • Lớp ${profile.grade} • Tuần ${profile.currentWeek}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: r.isCompactPhone ? 12.5 : 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton.filledTonal(
                  onPressed: onToggleBgm,
                  tooltip: bgmEnabled ? 'Tắt nhạc nền' : 'Bật nhạc nền',
                  icon: Icon(
                    bgmEnabled
                        ? Icons.music_note_rounded
                        : Icons.music_off_rounded,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton.filledTonal(
                  onPressed: onToggleMute,
                  tooltip: isMuted ? 'Bật âm thanh' : 'Tắt âm thanh',
                  icon: Icon(
                    isMuted
                        ? Icons.volume_off_rounded
                        : Icons.volume_up_rounded,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton.filledTonal(
                  onPressed: onOpenParentGate,
                  tooltip: 'Cổng phụ huynh',
                  icon: const Icon(Icons.admin_panel_settings_rounded),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3B0),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '⭐ ${profile.stars} Sao thưởng • Chạm bạn Cú để đổi phụ kiện!',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: r.isCompactPhone ? 11.5 : 12.5,
                color: const Color(0xFF92400E),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMascotSection(ResponsiveLayout r) {
    return Center(
      child: GestureDetector(
        onTap: onCycleAccessory,
        child: AnimatedOwlMascot(
          mood: isUnlocked ? OwlMood.happy : OwlMood.idle,
          size: r.owlHeroSize,
          accessory: profile.owlAccessory,
        ),
      ),
    );
  }

  Widget _buildInfoSection(ResponsiveLayout r, bool capReached) {
    if (isUnlocked) {
      return Column(
        children: [
          Text(
            '🎉 Đang mở khóa cho ${profile.name}!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: r.titleFontSize,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F766E),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF34D399), width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withValues(alpha: 0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  '⏳ ${_formatClock(remainingSeconds)}',
                  style: TextStyle(
                    fontSize: r.isCompactPhone ? 30 : 38,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF059669),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Thời gian giải trí còn lại (bảo lưu khi tắt màn hình)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: r.isCompactPhone ? 12 : 13.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Text(
          capReached
              ? 'Hôm nay ${profile.name} đã dùng đủ giờ rồi!'
              : 'Hết giờ giải trí rồi, ${profile.name} ơi!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: r.titleFontSize,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF2B2D42),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          capReached
              ? 'Mắt cần nghỉ ngơi nhé. Ngày mai đồng hồ sẽ tự động đặt lại lúc 00:00.'
              : 'Hoàn thành ${nextChallenge.questionCount} câu hỏi (${nextChallenge.targetDifficulty.label}) để nhận thêm +${nextChallenge.rewardMinutes} phút nhé!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: r.bodyFontSize,
            height: 1.4,
            color: const Color(0xFF475569),
          ),
        ),
        if (!capReached) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFBAE6FD)),
            ),
            child: Text(
              '⭐ Lượt xin thêm hôm nay: Lần ${nextChallenge.turnNumber} • Độ khó: ${nextChallenge.targetDifficulty.label}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: r.isCompactPhone ? 13 : 14.5,
                color: const Color(0xFF0369A1),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildUnlockedAppsGrid(ResponsiveLayout r) {
    if (unlockedApps.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        Text(
          '🔓 Bấm vào ứng dụng bên dưới để mở ngay:',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: r.isCompactPhone ? 13 : 14.5,
            color: const Color(0xFF0F766E),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: unlockedApps.take(8).map((app) {
            final meta = _iconMeta(app);
            return InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => onLaunchApp(app.packageName),
              child: Container(
                width: r.isCompactPhone ? 96 : 112,
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF6EE7B7), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: meta.$2.withValues(alpha: 0.14),
                          child:
                              Text(meta.$1, style: const TextStyle(fontSize: 20)),
                        ),
                        const Positioned(
                          right: -4,
                          bottom: -2,
                          child: Text('🔓', style: TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      app.appName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ResponsiveLayout r, bool capReached) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isUnlocked && profile.isAudioFirstGrade)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Tactile3DButton(
              color: const Color(0xFF38BDF8),
              shadowColor: const Color(0xFF0284C7),
              onPressed: onSpeakWelcome,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.hearing_rounded,
                      color: Colors.white, size: 24),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Nghe bạn Cú hướng dẫn',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: r.buttonFontSize - 1,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Tactile3DButton(
          color: isUnlocked
              ? const Color(0xFF10B981)
              : const Color(0xFFFF8C42),
          shadowColor: isUnlocked
              ? const Color(0xFF047857)
              : const Color(0xFFD16014),
          padding: EdgeInsets.symmetric(
            horizontal: 14,
            vertical: r.isCompactPhone ? 14 : 18,
          ),
          onPressed: capReached ? null : onStartQuiz,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                capReached
                    ? Icons.bedtime_rounded
                    : (isUnlocked
                        ? Icons.auto_awesome_rounded
                        : Icons.play_arrow_rounded),
                color: Colors.white,
                size: 26,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  capReached
                      ? 'Hẹn bé ngày mai nhé'
                      : (isUnlocked
                          ? 'Học thêm ${nextChallenge.questionCount} câu nhận +${nextChallenge.rewardMinutes} phút & ⭐'
                          : 'Làm ${nextChallenge.questionCount} câu nhận +${nextChallenge.rewardMinutes} phút'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: r.buttonFontSize,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
