import 'package:flutter/material.dart';
import '../../core/models/child_profile.dart';
import '../../core/models/question.dart';
import '../../core/services/audio_guide_service.dart';
import '../../core/services/escalation_engine.dart';

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

class _QuizScreenState extends State<QuizScreen> {
  int _currentIndex = 0;
  int _correctCount = 0;
  bool _showHint = false;
  int? _wrongSelectedIndex;

  @override
  void initState() {
    super.initState();
    _autoSpeakCurrent();
  }

  void _autoSpeakCurrent() {
    if (widget.profile.isAudioFirstGrade && widget.questions.isNotEmpty) {
      widget.audioGuide.speak(widget.questions[_currentIndex].audioText);
    }
  }

  void _handleOptionTap(int index) {
    final question = widget.questions[_currentIndex];
    if (index == question.correctIndex) {
      _correctCount++;
      widget.audioGuide.speak('Giỏi quá! Đúng rồi!');

      if (_currentIndex + 1 >= widget.questions.length) {
        widget.onCompleted(_correctCount);
      } else {
        setState(() {
          _currentIndex++;
          _showHint = false;
          _wrongSelectedIndex = null;
        });
        _autoSpeakCurrent();
      }
    } else {
      // Không phạt nặng: hiện gợi ý nhẹ nhàng & đọc lại cho bé hiểu.
      setState(() {
        _showHint = true;
        _wrongSelectedIndex = index;
      });
      widget.audioGuide.speak(
        'Chưa đúng rồi, mình thử lại nhé! ${question.hintText}',
      );
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
          IconButton(
            onPressed: () => widget.audioGuide.speak(question.audioText),
            icon: const Icon(Icons.volume_up_rounded, size: 30),
            tooltip: 'Nghe lại câu hỏi',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
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
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
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
                        style: const TextStyle(fontSize: 34),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      question.prompt,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isBigButtons ? 22 : 19,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () =>
                          widget.audioGuide.speak(question.audioText),
                      icon: const Icon(Icons.hearing_rounded),
                      label: const Text('Bấm để nghe lại câu hỏi'),
                    ),
                  ],
                ),
              ),
              if (_showHint) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4D6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFC857)),
                  ),
                  child: Row(
                    children: [
                      const Text('💡', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          question.hintText,
                          style: const TextStyle(
                            fontSize: 15,
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
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.65,
                ),
                itemCount: question.options.length,
                itemBuilder: (context, index) {
                  final isWrong = _wrongSelectedIndex == index;
                  return ElevatedButton(
                    onPressed: () => _handleOptionTap(index),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isWrong
                          ? const Color(0xFFFFE3E3)
                          : const Color(0xFF3A86FF),
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
                        fontSize: isBigButtons ? 22 : 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
