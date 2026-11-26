import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/models/child_profile.dart';
import '../../core/models/daily_usage_state.dart';
import '../../core/platform/device_lock_service.dart';
import '../../core/services/audio_guide_service.dart';

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({
    super.key,
    required this.profile,
    required this.usageState,
    required this.audioGuide,
    required this.deviceLockService,
    required this.onSaveProfile,
    required this.onSimulateTimeUp,
    required this.onRequestPermissions,
    required this.onSyncQuestionsNow,
    required this.onSyncDeviceUsageNow,
  });

  final ChildProfile profile;
  final DailyUsageState usageState;
  final AudioGuideService audioGuide;
  final DeviceLockService deviceLockService;
  final ValueChanged<ChildProfile> onSaveProfile;
  final VoidCallback onSimulateTimeUp;
  final VoidCallback onRequestPermissions;
  final Future<int> Function(String repo) onSyncQuestionsNow;
  final Future<String> Function(String repo, String token) onSyncDeviceUsageNow;

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _parentNameController;
  late final TextEditingController _pinController;
  late final TextEditingController _locationController;
  late final TextEditingController _githubRepoController;
  late final TextEditingController _githubTokenController;
  late int _age;
  late int _grade;
  late TextbookSeries _textbook;
  late int _week;
  late int _baseMinutes;
  late int _maxMinutes;
  late int _extensionMinutes;
  late int _baseQuestions;

  // Tùy chỉnh giọng đọc & âm thanh tiếng Việt
  late double _speechRate;
  late double _speechPitch;
  late String _voiceName;
  late SfxStyle _sfxStyle;
  List<VoiceOption> _availableVoices = const [];

  // Danh sách ứng dụng bị khóa trên máy
  late Set<String> _blockedPackages;
  List<InstalledAppInfo> _installedApps = const [];
  bool _hasPermissions = false;
  bool _isAdminActive = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _parentNameController =
        TextEditingController(text: widget.profile.parentName);
    _pinController = TextEditingController(text: widget.profile.parentPin);
    _locationController = TextEditingController(text: widget.profile.location);
    _githubRepoController =
        TextEditingController(text: widget.profile.githubRepo);
    _githubTokenController =
        TextEditingController(text: widget.profile.githubToken);
    _age = widget.profile.age;
    _grade = widget.profile.grade;
    _textbook = widget.profile.textbook;
    _week = widget.profile.currentWeek;
    _baseMinutes = widget.profile.dailyBaseMinutes;
    _maxMinutes = widget.profile.dailyMaxMinutes;
    _extensionMinutes = widget.profile.extensionMinutes;
    _baseQuestions = widget.profile.baseQuestions;
    _speechRate = widget.profile.speechRate;
    _speechPitch = widget.profile.speechPitch;
    _voiceName = widget.profile.voiceName;
    _sfxStyle = widget.profile.sfxStyle;
    _blockedPackages = widget.profile.blockedPackages.toSet();
    _loadVoices();
    _loadDeviceAppsAndPermissions();
  }

  Future<void> _checkAndSelfUpdateApp() async {
    final repo = _githubRepoController.text.trim().isEmpty
        ? 'newsboy01/LockWill'
        : _githubRepoController.text.trim();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đang kiểm tra phiên bản mới từ GitHub...')),
    );
    try {
      final res = await http
          .get(
            Uri.parse(
              'https://github.com/$repo/releases/download/latest-apk/version.json',
            ),
            headers: const {'User-Agent': 'LockWill-App'},
          )
          .timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chưa thấy bản phát hành mới (HTTP ${res.statusCode}).')),
        );
        return;
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final remoteCode = (data['versionCode'] as num?)?.toInt() ?? 0;
      final apkUrl = (data['apkUrl'] as String?) ?? '';
      final localCode = await widget.deviceLockService.getAppVersionCode();

      if (remoteCode <= localCode) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('App đang ở bản mới nhất (#$localCode)!')),
        );
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tìm thấy bản mới (#$remoteCode)! Đang tải trực tiếp vào máy...'),
        ),
      );
      final msg = await widget.deviceLockService.downloadAndInstallApk(apkUrl);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi kiểm tra cập nhật: $e')),
      );
    }
  }

  Future<void> _loadDeviceAppsAndPermissions() async {
    final perm = await widget.deviceLockService.hasRequiredPermissions();
    final admin = await widget.deviceLockService.isDeviceAdminActive();
    final apps = await widget.deviceLockService.getInstalledApps();
    if (!mounted) return;
    setState(() {
      _hasPermissions = perm;
      _isAdminActive = admin;
      _installedApps = apps;
    });
  }

  Future<void> _openAppPickerDialog() async {
    var query = '';
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final filtered = _installedApps
                .where((a) =>
                    a.appName.toLowerCase().contains(query.toLowerCase()) ||
                    a.packageName.toLowerCase().contains(query.toLowerCase()))
                .toList();
            return AlertDialog(
              title: Text('Chọn App bị khóa (${_blockedPackages.length})'),
              content: SizedBox(
                width: double.maxFinite,
                height: 380,
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Tìm YouTube, TikTok, Game...',
                        prefixIcon: Icon(Icons.search),
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) => setModalState(() => query = v),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (_, idx) {
                          final app = filtered[idx];
                          final checked =
                              _blockedPackages.contains(app.packageName);
                          return CheckboxListTile(
                            dense: true,
                            value: checked,
                            title: Text(app.appName),
                            subtitle: Text(
                              app.packageName,
                              style: const TextStyle(fontSize: 11),
                            ),
                            onChanged: (v) {
                              setModalState(() {
                                if (v == true) {
                                  _blockedPackages.add(app.packageName);
                                } else {
                                  _blockedPackages.remove(app.packageName);
                                }
                              });
                              setState(() {});
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Xong'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _loadVoices() async {
    final voices = await widget.audioGuide.getVietnameseVoices();
    if (!mounted) return;
    setState(() {
      _availableVoices = voices;
      if (_voiceName.isNotEmpty &&
          !voices.any((v) => v.name == _voiceName)) {
        _voiceName = '';
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _parentNameController.dispose();
    _pinController.dispose();
    _locationController.dispose();
    _githubRepoController.dispose();
    _githubTokenController.dispose();
    super.dispose();
  }

  String _rateLabel(double rate) {
    if (rate <= 0.35) return 'Rất chậm (Phù hợp Lớp 1 mới tập nghe)';
    if (rate <= 0.48) return 'Chậm rõ ràng (Chuẩn Lớp 1–2)';
    if (rate <= 0.60) return 'Vừa phải (Chuẩn Lớp 3–4)';
    return 'Nhanh tự nhiên (Lớp 5)';
  }

  String _pitchLabel(double pitch) {
    if (pitch <= 0.92) return 'Trầm ấm';
    if (pitch <= 1.12) return 'Tự nhiên';
    return 'Tươi vui (Trẻ em yêu thích)';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ Bé & Cài đặt Phụ huynh'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thống kê hôm nay: ${widget.profile.name} (${widget.profile.age} tuổi)',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Đã dùng: ${widget.usageState.usedMinutes}/${widget.usageState.grantedMinutes} phút '
                    '• Gia hạn: ${widget.usageState.extensionCountToday} lần '
                    '• Trả lời đúng: ${widget.usageState.totalCorrectToday} câu',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          widget.onRequestPermissions();
                          Future<void>.delayed(
                            const Duration(seconds: 2),
                            _loadDeviceAppsAndPermissions,
                          );
                        },
                        icon: Icon(
                          _hasPermissions
                              ? Icons.verified_user_rounded
                              : Icons.security_rounded,
                        ),
                        label: Text(
                          _hasPermissions
                              ? 'Đã cấp quyền khóa Android ✅'
                              : 'Cấp quyền khóa Android',
                        ),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: _openAppPickerDialog,
                        icon: const Icon(Icons.apps_rounded),
                        label: Text(
                          'Chọn App bị khóa (${_blockedPackages.length})',
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await widget.deviceLockService.requestDeviceAdmin();
                          Future<void>.delayed(
                            const Duration(seconds: 2),
                            _loadDeviceAppsAndPermissions,
                          );
                        },
                        icon: Icon(
                          _isAdminActive
                              ? Icons.shield_rounded
                              : Icons.admin_panel_settings_outlined,
                        ),
                        label: Text(
                          _isAdminActive
                              ? 'Chống gỡ app: ĐÃ BẬT ✅'
                              : 'Bật chống tự gỡ app',
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => widget.deviceLockService
                            .requestIgnoreBatteryOptimization(),
                        icon: const Icon(Icons.battery_saver_rounded),
                        label: const Text('Tắt tối ưu pin (Chạy nền bền)'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: widget.onSimulateTimeUp,
                        icon: const Icon(Icons.lock_clock_rounded),
                        label: const Text('Khóa ngay (Test hết giờ)'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '1. Thông tin hồ sơ của bé',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Tên gọi của bé',
              prefixIcon: Icon(Icons.child_care_rounded),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _parentNameController,
            decoration: const InputDecoration(
              labelText: 'Tên Bố/Mẹ giám sát',
              prefixIcon: Icon(Icons.supervisor_account_rounded),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _locationController,
            decoration: const InputDecoration(
              labelText: 'Vị trí / Khu vực (VD: Quận 7, TP.HCM)',
              prefixIcon: Icon(Icons.location_on_rounded),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _age.clamp(6, 11),
                  decoration: const InputDecoration(
                    labelText: 'Tuổi',
                    border: OutlineInputBorder(),
                  ),
                  items: [6, 7, 8, 9, 10, 11]
                      .map((a) =>
                          DropdownMenuItem(value: a, child: Text('$a tuổi')))
                      .toList(),
                  onChanged: (v) => setState(() => _age = v ?? 6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _grade.clamp(1, 5),
                  decoration: const InputDecoration(
                    labelText: 'Lớp học',
                    border: OutlineInputBorder(),
                  ),
                  items: [1, 2, 3, 4, 5]
                      .map((g) =>
                          DropdownMenuItem(value: g, child: Text('Lớp $g')))
                      .toList(),
                  onChanged: (v) => setState(() => _grade = v ?? 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<TextbookSeries>(
            value: _textbook,
            decoration: const InputDecoration(
              labelText: 'Bộ sách nhà trường đang dạy',
              border: OutlineInputBorder(),
            ),
            items: TextbookSeries.values
                .map(
                  (t) => DropdownMenuItem(
                    value: t,
                    child: Text(t.displayName),
                  ),
                )
                .toList(),
            onChanged: (v) =>
                setState(() => _textbook = v ?? TextbookSeries.ketNoiTriThuc),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Text('Tuần học hiện tại: Tuần $_week')),
              IconButton(
                onPressed: () =>
                    setState(() => _week = (_week - 1).clamp(1, 35)),
                icon: const Icon(Icons.remove_circle_outline),
              ),
              IconButton(
                onPressed: () =>
                    setState(() => _week = (_week + 1).clamp(1, 35)),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const Divider(height: 30),
          const Text(
            '2. Tùy chỉnh Giọng đọc Tiếng Việt & Âm thanh',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _voiceName,
            decoration: const InputDecoration(
              labelText: 'Giọng đọc Tiếng Việt trên thiết bị',
              prefixIcon: Icon(Icons.record_voice_over_rounded),
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(
                value: '',
                child: Text('Mặc định chuẩn Tiếng Việt (vi-VN)'),
              ),
              ..._availableVoices.map(
                (v) => DropdownMenuItem(
                  value: v.name,
                  child: Text(v.label, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
            onChanged: (v) => setState(() => _voiceName = v ?? ''),
          ),
          const SizedBox(height: 12),
          Text('Tốc độ đọc: ${_rateLabel(_speechRate)}'),
          Slider(
            value: _speechRate.clamp(0.25, 0.75),
            min: 0.25,
            max: 0.75,
            divisions: 10,
            label: _speechRate.toStringAsFixed(2),
            onChanged: (v) => setState(() => _speechRate = v),
          ),
          Text('Ngữ điệu / Cao độ: ${_pitchLabel(_speechPitch)}'),
          Slider(
            value: _speechPitch.clamp(0.8, 1.3),
            min: 0.8,
            max: 1.3,
            divisions: 10,
            label: _speechPitch.toStringAsFixed(2),
            onChanged: (v) => setState(() => _speechPitch = v),
          ),
          DropdownButtonFormField<SfxStyle>(
            value: _sfxStyle,
            decoration: const InputDecoration(
              labelText: 'Kiểu âm thanh hiệu ứng (Đúng / Sai)',
              prefixIcon: Icon(Icons.music_note_rounded),
              border: OutlineInputBorder(),
            ),
            items: SfxStyle.values
                .map(
                  (s) => DropdownMenuItem(
                    value: s,
                    child: Text(s.displayName),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _sfxStyle = v ?? SfxStyle.cheerful),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              final name = _nameController.text.trim().isEmpty
                  ? 'bé'
                  : _nameController.text.trim();
              widget.audioGuide.testVoice(
                rate: _speechRate,
                pitch: _speechPitch,
                voiceName: _voiceName,
                sampleText:
                    'Chào $name! Bạn Cú mèo đang đọc thử giọng tiếng Việt cho lớp $_grade nè!',
              );
            },
            icon: const Icon(Icons.play_circle_fill_rounded),
            label: const Text('Nghe thử giọng đọc hiện tại'),
          ),
          const Divider(height: 30),
          const Text(
            '3. Thời gian sử dụng, Bậc thang Gia hạn & Bảo mật',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text('Quỹ thời gian mặc định đầu ngày: $_baseMinutes phút'),
          Slider(
            value: _baseMinutes.toDouble().clamp(10, 90),
            min: 10,
            max: 90,
            divisions: 16,
            label: '$_baseMinutes phút',
            onChanged: (v) => setState(() => _baseMinutes = v.round()),
          ),
          Text('Giới hạn trần tối đa mỗi ngày: $_maxMinutes phút (${(_maxMinutes / 60).toStringAsFixed(1)} giờ)'),
          Slider(
            value: _maxMinutes.toDouble().clamp(60, 480),
            min: 60,
            max: 480,
            divisions: 14,
            label: '$_maxMinutes phút',
            onChanged: (v) => setState(() => _maxMinutes = v.round()),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: [5, 10, 15, 20, 30].contains(_extensionMinutes)
                ? _extensionMinutes
                : 15,
            decoration: const InputDecoration(
              labelText: 'Thời lượng mỗi lần gia hạn thêm',
              prefixIcon: Icon(Icons.more_time_rounded),
              border: OutlineInputBorder(),
            ),
            items: [5, 10, 15, 20, 30]
                .map((m) => DropdownMenuItem(
                      value: m,
                      child: Text('+$m phút mỗi lần làm bài'),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _extensionMinutes = v ?? 15),
          ),
          const SizedBox(height: 10),
          Text(
            'Số câu hỏi chuẩn (mốc 15 phút): $_baseQuestions câu → Lượt 1 (+$_extensionMinutes phút) cần ${((_baseQuestions * _extensionMinutes) / 15.0).round().clamp(3, 25)} câu, các lượt sau +2 câu & tăng dần độ khó trong lớp $_grade.',
            style: const TextStyle(fontSize: 13),
          ),
          Slider(
            value: _baseQuestions.toDouble().clamp(3, 15),
            min: 3,
            max: 15,
            divisions: 12,
            label: '$_baseQuestions câu',
            onChanged: (v) => setState(() => _baseQuestions = v.round()),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: 'Mã PIN Phụ huynh',
              prefixIcon: Icon(Icons.lock_rounded),
              border: OutlineInputBorder(),
            ),
          ),
          const Divider(height: 30),
          const Text(
            '4. Tự động cập nhật & Đồng bộ Báo cáo GitHub',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _githubRepoController,
            decoration: const InputDecoration(
              labelText: 'Kho GitHub (VD: newsboy01/LockWill)',
              prefixIcon: Icon(Icons.cloud_sync_rounded),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _githubTokenController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'GitHub Token (để tự đẩy báo cáo học tập của bé)',
              prefixIcon: Icon(Icons.vpn_key_rounded),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  final count = await widget.onSyncQuestionsNow(
                    _githubRepoController.text.trim(),
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        count > 0
                            ? 'Đã tải $count câu hỏi mới nhất từ GitHub!'
                            : 'Không kết nối được GitHub, đang dùng dữ liệu offline.',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.download_for_offline_rounded),
                label: const Text('Cập nhật bộ câu hỏi từ GitHub'),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  final status = await widget.onSyncDeviceUsageNow(
                    _githubRepoController.text.trim(),
                    _githubTokenController.text.trim(),
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(status)),
                  );
                },
                icon: const Icon(Icons.cloud_upload_rounded),
                label: const Text('Đẩy lịch sử dùng máy lên Web ngay'),
              ),
              FilledButton.tonalIcon(
                onPressed: _checkAndSelfUpdateApp,
                icon: const Icon(Icons.system_update_rounded),
                label: const Text('Tự kiểm tra & Cập nhật App (1 chạm)'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              final cleanName = _nameController.text.trim();
              final cleanParent = _parentNameController.text.trim();
              final cleanPin = _pinController.text.trim();
              final cleanLocation = _locationController.text.trim();
              final cleanRepo = _githubRepoController.text.trim();
              widget.onSaveProfile(
                widget.profile.copyWith(
                  name: cleanName.isEmpty ? 'Bé' : cleanName,
                  parentName: cleanParent.isEmpty ? 'Phụ huynh' : cleanParent,
                  age: _age,
                  grade: _grade,
                  textbook: _textbook,
                  currentWeek: _week,
                  dailyBaseMinutes: _baseMinutes,
                  dailyMaxMinutes: _maxMinutes,
                  extensionMinutes: _extensionMinutes,
                  baseQuestions: _baseQuestions,
                  parentPin: cleanPin.isEmpty ? '1234' : cleanPin,
                  speechRate: _speechRate,
                  speechPitch: _speechPitch,
                  voiceName: _voiceName,
                  sfxStyle: _sfxStyle,
                  location: cleanLocation.isEmpty ? 'Việt Nam' : cleanLocation,
                  githubRepo:
                      cleanRepo.isEmpty ? 'newsboy01/LockWill' : cleanRepo,
                  githubToken: _githubTokenController.text.trim(),
                  blockedPackages: _blockedPackages.toList(),
                ),
              );
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.save_rounded),
            label: const Text('Lưu hồ sơ & cấu hình'),
          ),
        ],
      ),
    );
  }
}
