import 'package:flutter/material.dart';
import '../../core/models/child_profile.dart';
import '../../core/models/daily_usage_state.dart';

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({
    super.key,
    required this.profile,
    required this.usageState,
    required this.onSaveProfile,
    required this.onSimulateTimeUp,
    required this.onRequestPermissions,
  });

  final ChildProfile profile;
  final DailyUsageState usageState;
  final ValueChanged<ChildProfile> onSaveProfile;
  final VoidCallback onSimulateTimeUp;
  final VoidCallback onRequestPermissions;

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _pinController;
  late int _age;
  late int _grade;
  late TextbookSeries _textbook;
  late int _week;
  late int _baseMinutes;
  late int _maxMinutes;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _pinController = TextEditingController(text: widget.profile.parentPin);
    _age = widget.profile.age;
    _grade = widget.profile.grade;
    _textbook = widget.profile.textbook;
    _week = widget.profile.currentWeek;
    _baseMinutes = widget.profile.dailyBaseMinutes;
    _maxMinutes = widget.profile.dailyMaxMinutes;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    super.dispose();
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
                        onPressed: widget.onRequestPermissions,
                        icon: const Icon(Icons.security_rounded),
                        label: const Text('Cấp quyền khóa Android'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: widget.onSimulateTimeUp,
                        icon: const Icon(Icons.lock_clock_rounded),
                        label: const Text('Test màn hình hết giờ'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Thông tin hồ sơ của bé',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
          const Divider(height: 28),
          Text('Quỹ thời gian mặc định đầu ngày: $_baseMinutes phút'),
          Slider(
            value: _baseMinutes.toDouble(),
            min: 15,
            max: 60,
            divisions: 9,
            label: '$_baseMinutes phút',
            onChanged: (v) => setState(() => _baseMinutes = v.round()),
          ),
          Text('Giới hạn trần tối đa mỗi ngày: $_maxMinutes phút'),
          Slider(
            value: _maxMinutes.toDouble(),
            min: 45,
            max: 150,
            divisions: 7,
            label: '$_maxMinutes phút',
            onChanged: (v) => setState(() => _maxMinutes = v.round()),
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
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () {
              final cleanName = _nameController.text.trim();
              final cleanPin = _pinController.text.trim();
              widget.onSaveProfile(
                widget.profile.copyWith(
                  name: cleanName.isEmpty ? 'Bé' : cleanName,
                  age: _age,
                  grade: _grade,
                  textbook: _textbook,
                  currentWeek: _week,
                  dailyBaseMinutes: _baseMinutes,
                  dailyMaxMinutes: _maxMinutes,
                  parentPin: cleanPin.isEmpty ? '1234' : cleanPin,
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
