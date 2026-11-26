import 'package:flutter/material.dart';
import '../../core/models/child_profile.dart';
import '../../core/services/curriculum_service.dart';
import '../../core/widgets/animated_owl_mascot.dart';
import '../../core/widgets/tactile_3d_button.dart';

/// Màn hình Thiết lập Lần Đầu khi mới cài app để phụ huynh nhập sẵn thông tin bé,
/// tên bố mẹ giám sát và mã PIN giúp lọc thư viện câu hỏi chuẩn xác ngay từ đầu.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.initialProfile,
    required this.onCompleted,
  });

  final ChildProfile initialProfile;
  final ValueChanged<ChildProfile> onCompleted;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _childNameCtrl = TextEditingController();
  final _parentNameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController(text: 'TP.HCM');
  final _pinCtrl = TextEditingController(text: '1234');

  int _age = 6;
  int _grade = 1;
  TextbookSeries _textbook = TextbookSeries.ketNoiTriThuc;
  String? _pinError;

  @override
  void dispose() {
    _childNameCtrl.dispose();
    _parentNameCtrl.dispose();
    _locationCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  void _finish() {
    final pin = _pinCtrl.text.trim();
    if (pin.length < 4) {
      setState(() => _pinError = 'Vui lòng nhập mã PIN ít nhất 4 chữ số');
      return;
    }

    final childName =
        _childNameCtrl.text.trim().isEmpty ? 'Bé Minh' : _childNameCtrl.text.trim();
    final parentName = _parentNameCtrl.text.trim().isEmpty
        ? 'Phụ huynh'
        : _parentNameCtrl.text.trim();
    final location =
        _locationCtrl.text.trim().isEmpty ? 'Việt Nam' : _locationCtrl.text.trim();

    widget.onCompleted(
      widget.initialProfile.copyWith(
        name: childName,
        age: _age,
        grade: _grade,
        textbook: _textbook,
        currentWeek: CurriculumService.estimateCurrentSchoolWeek(),
        parentName: parentName,
        location: location,
        parentPin: pin,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF3E0), Color(0xFFE6F6FF)],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(22),
            children: [
              const Center(
                child: AnimatedOwlMascot(
                  mood: OwlMood.happy,
                  size: 118,
                  accessory: 'grad_cap',
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Chào mừng đến với LockWill!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Phụ huynh hãy điền nhanh thông tin để ứng dụng chọn đúng thư viện kiến thức theo lớp của bé nhé.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 18),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      TextField(
                        controller: _childNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Tên của bé (VD: Bé Minh)',
                          prefixIcon: Icon(Icons.child_care_rounded),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _age,
                              decoration: const InputDecoration(
                                labelText: 'Tuổi của bé',
                                border: OutlineInputBorder(),
                              ),
                              items: [6, 7, 8, 9, 10, 11]
                                  .map((a) => DropdownMenuItem(
                                        value: a,
                                        child: Text('$a tuổi'),
                                      ))
                                  .toList(),
                              onChanged: (v) => setState(() => _age = v ?? 6),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _grade,
                              decoration: const InputDecoration(
                                labelText: 'Kiến thức Lớp',
                                border: OutlineInputBorder(),
                              ),
                              items: [1, 2, 3, 4, 5]
                                  .map((g) => DropdownMenuItem(
                                        value: g,
                                        child: Text('Lớp $g'),
                                      ))
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
                          prefixIcon: Icon(Icons.menu_book_rounded),
                          border: OutlineInputBorder(),
                        ),
                        items: TextbookSeries.values
                            .map((t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(t.displayName),
                                ))
                            .toList(),
                        onChanged: (v) => setState(
                            () => _textbook = v ?? TextbookSeries.ketNoiTriThuc),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _parentNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Tên Bố/Mẹ giám sát',
                          prefixIcon: Icon(Icons.supervisor_account_rounded),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _locationCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Vị trí / Khu vực (VD: Quận 7, TP.HCM)',
                          prefixIcon: Icon(Icons.location_on_rounded),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _pinCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: InputDecoration(
                          labelText: 'Mật khẩu PIN Phụ huynh (4–6 số)',
                          prefixIcon: const Icon(Icons.lock_rounded),
                          errorText: _pinError,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Tactile3DButton(
                color: const Color(0xFFFF8C42),
                shadowColor: const Color(0xFFD16014),
                padding: const EdgeInsets.symmetric(vertical: 16),
                onPressed: _finish,
                child: const Text(
                  'Hoàn tất & Bắt đầu sử dụng 🚀',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
