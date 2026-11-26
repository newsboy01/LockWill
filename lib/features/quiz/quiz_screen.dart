import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/models/child_profile.dart';
import '../../core/models/question.dart';
import '../../core/services/audio_guide_service.dart';
import '../../core/services/escalation_engine.dart';
import '../../core/widgets/animated_owl_mascot.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({
    super.key,
    required this.profile,
    required this.challenge,
    required this.questions,
    required this.audioGuide,
    required this.onCompleted,
  });

  final ChildProfile profile;
  final ExtensionChallenge challenge;
  final List<Question> questions;
  final AudioGuideService audioGuide;
  final void Function(int correctCount) onCompleted;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  int _correctCount = 0;
  int _streak = 0;
  bool _showHint = false;
  bool _isTransitioning = false;
  int? _wrongSelectedIndex;
  int? _correctSelectedIndex;
  String _typedNumber = '';
  OwlMood _owlMood = OwlMood.idle;

  late final AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _autoSpeakCurrent();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _autoSpeakCurrent() {
    if (widget.profile.isAudioFirstGrade && widget.questions.isNotEmpty) {
      widget.audioGuide.speak(widget.questions[_currentIndex].audioText);
    }
  }

  Future<void> _onCorrectAnswer({int? selectedIndex}) async {
    if (_isTransitioning) return;
    _isTransitioning = true;
    _correctCount++;
    _streak++;

    setState(() {
      _owlMood = OwlMood.happy;
      _correctSelectedIndex = selectedIndex;
      _wrongSelectedIndex = null;
      _showHint = false;
    });

    await widget.audioGuide.playCorrectSound();
    if (widget.profile.isAudioFirstGrade) {
      await widget.audioGuide.speak('Giỏi quá! Đúng rồi!');
    }

    await Future<void>.delayed(const Duration(milliseconds: 750));
    if (!mounted) return;

    if (_currentIndex + 1 >= widget.questions.length) {
      widget.onCompleted(_correctCount);
      return;
    }

    setState(() {
      _currentIndex++;
      _owlMood = OwlMood.idle;
      _correctSelectedIndex = null;
      _wrongSelectedIndex = null;
      _typedNumber = '';
      _isTransitioning = false;
    });
    _autoSpeakCurrent();
  }

  Future<void> _onWrongAnswer({int? selectedIndex}) async {
    if (_isTransitioning) return;
    final question = widget.questions[_currentIndex];
    _streak = 0;

    setState(() {
      _owlMood = OwlMood.encourage;
      _showHint = true;
      _wrongSelectedIndex = selectedIndex;
    });

    _shakeController.forward(from: 0);
    await widget.audioGuide.playWrongSound();
    await widget.audioGuide.speak(
      'Chưa đúng rồi, mình thử lại nhé! ${question.hintText}',
    );
  }

  void _submitTypedNumber() {
    final question = widget.questions[_currentIndex];
    if (_typedNumber.isEmpty) return;
    if (_typedNumber == question.options.first) {
      _onCorrectAnswer();
    } else {
      _onWrongAnswer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.questions[_currentIndex];
    final isBigButtons = widget.profile.isAudioFirstGrade;

    return Scaffold(
      backgroundColor: const Color(0xFFF3FAFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Câu ${_currentIndex + 1}/${widget.questions.length} • ${question.subject}',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          if (_streak >= 2)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3B0),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '🔥 $_streak',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          IconButton(
            onPressed: () => widget.audioGuide.speak(question.audioText),
            icon: const Icon(Icons.volume_up_rounded, size: 30),
            tooltip: 'Nghe lại câu hỏi',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(
                value: (_currentIndex + 1) / widget.questions.length,
                minHeight: 12,
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFF2EC4B6),
                backgroundColor: const Color(0xFFDCEEF8),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  AnimatedOwlMascot(mood: _owlMood, size: 68),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _owlMood == OwlMood.happy
                            ? 'Tuyệt vời! Bé giỏi quá 🎉'
                            : (_owlMood == OwlMood.encourage
                                ? 'Cố lên! Đọc gợi ý bên dưới nhé 💪'
                                : 'Bạn Cú đang cổ vũ ${widget.profile.name} đó!'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AnimatedBuilder(
                animation: _shakeController,
                builder: (context, child) {
                  final dx =
                      math.sin(_shakeController.value * math.pi * 4) * 10;
                  return Transform.translate(
                    offset: Offset(dx, 0),
                    child: child,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _owlMood == OwlMood.happy
                          ? const Color(0xFF2EC4B6)
                          : (_owlMood == OwlMood.encourage
                              ? const Color(0xFFFF8C42)
                              : Colors.transparent),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      if (question.visualEmoji.isNotEmpty) ...[
                        Text(
                          question.visualEmoji,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 32),
                        ),
                        const SizedBox(height: 10),
                      ],
                      Text(
                        question.prompt,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isBigButtons ? 21 : 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_showHint) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4D6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFC857)),
                  ),
                  child: Row(
                    children: [
                      const Text('💡', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          question.hintText,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF7A4E00),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              if (question.type == 'fill_number')
                _buildNumberPad(isBigButtons)
              else
                _buildOptionGrid(question, isBigButtons),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionGrid(Question question, bool isBigButtons) {
    final crossAxisCount = question.options.length == 3 ? 3 : 2;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: question.options.length == 2 ? 1.8 : 1.65,
      ),
      itemCount: question.options.length,
      itemBuilder: (context, index) {
        final isWrong = _wrongSelectedIndex == index;
        final isCorrect = _correctSelectedIndex == index;
        return AnimatedScale(
          scale: isCorrect ? 1.06 : 1.0,
          duration: const Duration(milliseconds: 180),
          child: ElevatedButton(
            onPressed: () {
              if (index == question.correctIndex) {
                _onCorrectAnswer(selectedIndex: index);
              } else {
                _onWrongAnswer(selectedIndex: index);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isCorrect
                  ? const Color(0xFF2EC4B6)
                  : (isWrong
                      ? const Color(0xFFFFE3E3)
                      : const Color(0xFF3A86FF)),
              foregroundColor:
                  isWrong ? const Color(0xFFB91C1C) : Colors.white,
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            child: Text(
              question.options[index],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isBigButtons ? 21 : 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNumberPad(bool isBigButtons) {
    final keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '⌫', '0', '✓'];
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF3A86FF), width: 2),
          ),
          child: Text(
            _typedNumber.isEmpty ? 'Nhập số đáp án...' : _typedNumber,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: _typedNumber.isEmpty ? 18 : 28,
              fontWeight: FontWeight.w800,
              color: _typedNumber.isEmpty
                  ? Colors.grey.shade400
                  : const Color(0xFF1D4ED8),
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.3,
          ),
          itemCount: keys.length,
          itemBuilder: (context, idx) {
            final label = keys[idx];
            final isSubmit = label == '✓';
            final isBackspace = label == '⌫';
            return ElevatedButton(
              onPressed: () {
                if (isSubmit) {
                  _submitTypedNumber();
                } else if (isBackspace) {
                  if (_typedNumber.isNotEmpty) {
                    setState(() {
                      _typedNumber =
                          _typedNumber.substring(0, _typedNumber.length - 1);
                    });
                  }
                } else if (_typedNumber.length < 5) {
                  setState(() => _typedNumber += label);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isSubmit
                    ? const Color(0xFF2EC4B6)
                    : (isBackspace
                        ? const Color(0xFFFFE5D9)
                        : Colors.white),
                foregroundColor: isSubmit
                    ? Colors.white
                    : (isBackspace
                        ? const Color(0xFFD9480F)
                        : const Color(0xFF1F2937)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: isBigButtons ? 22 : 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
