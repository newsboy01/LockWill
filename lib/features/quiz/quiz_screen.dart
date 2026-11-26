import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/models/child_profile.dart';
import '../../core/models/owl_pet_state.dart';
import '../../core/models/question.dart';
import '../../core/services/audio_guide_service.dart';
import '../../core/services/escalation_engine.dart';
import '../../core/ui/responsive_layout.dart';
import '../../core/widgets/animated_owl_mascot.dart';
import '../../core/widgets/tactile_3d_button.dart';

class QuizResultSummary {
  const QuizResultSummary({
    required this.totalQuestions,
    required this.firstTryCorrect,
    required this.wrongAttempts,
    required this.subjectBreakdown,
  });

  final int totalQuestions;
  final int firstTryCorrect;
  final int wrongAttempts;
  final Map<String, Map<String, int>> subjectBreakdown;
}

class QuizScreen extends StatefulWidget {
  const QuizScreen({
    super.key,
    required this.profile,
    required this.petState,
    required this.challenge,
    required this.questions,
    required this.audioGuide,
    required this.onCompleted,
  });

  final ChildProfile profile;
  final OwlPetState petState;
  final ExtensionChallenge challenge;
  final List<Question> questions;
  final AudioGuideService audioGuide;
  final void Function(QuizResultSummary summary) onCompleted;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  int _firstTryCorrect = 0;
  int _wrongAttempts = 0;
  bool _missedCurrentQuestion = false;
  final Map<String, Map<String, int>> _subjectBreakdown = {};
  int _streak = 0;
  bool _showHint = false;
  bool _isTransitioning = false;
  bool _isWrongCooldown = false;
  final Set<int> _disabledWrongIndices = <int>{};
  int? _wrongSelectedIndex;
  int? _correctSelectedIndex;

  String _typedNumber = '';
  final List<String> _builtPieces = <String>[];
  String? _droppedAnswer;

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
      _speakQuestionWithOptions(widget.questions[_currentIndex]);
    }
  }

  void _speakQuestionWithOptions(Question q) {
    if (widget.profile.isAudioFirstGrade &&
        (q.type == 'multiple_choice' || q.type == 'true_false') &&
        q.options.length <= 4) {
      final joined = q.options.join(', ');
      widget.audioGuide.speak('${q.audioText} Các đáp án là: $joined.');
    } else {
      widget.audioGuide.speak(q.audioText);
    }
  }

  Future<void> _onCorrectAnswer({int? selectedIndex}) async {
    if (_isTransitioning) return;
    _isTransitioning = true;
    final question = widget.questions[_currentIndex];
    final subjectKey = question.subject.split(' - ').first;
    final stats = _subjectBreakdown.putIfAbsent(
      subjectKey,
      () => {'correct': 0, 'wrong': 0},
    );
    if (!_missedCurrentQuestion) {
      _firstTryCorrect++;
      stats['correct'] = (stats['correct'] ?? 0) + 1;
    }
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

    await Future<void>.delayed(const Duration(milliseconds: 850));
    if (!mounted) return;

    if (_currentIndex + 1 >= widget.questions.length) {
      widget.onCompleted(
        QuizResultSummary(
          totalQuestions: widget.questions.length,
          firstTryCorrect: _firstTryCorrect,
          wrongAttempts: _wrongAttempts,
          subjectBreakdown: _subjectBreakdown,
        ),
      );
      return;
    }

    setState(() {
      _currentIndex++;
      _missedCurrentQuestion = false;
      _owlMood = OwlMood.idle;
      _correctSelectedIndex = null;
      _wrongSelectedIndex = null;
      _disabledWrongIndices.clear();
      _isWrongCooldown = false;
      _typedNumber = '';
      _builtPieces.clear();
      _droppedAnswer = null;
      _isTransitioning = false;
    });
    _autoSpeakCurrent();
  }

  Future<void> _onWrongAnswer({int? selectedIndex}) async {
    if (_isTransitioning || _isWrongCooldown) return;
    final question = widget.questions[_currentIndex];
    final subjectKey = question.subject.split(' - ').first;
    final stats = _subjectBreakdown.putIfAbsent(
      subjectKey,
      () => {'correct': 0, 'wrong': 0},
    );
    if (!_missedCurrentQuestion) {
      stats['wrong'] = (stats['wrong'] ?? 0) + 1;
    }
    _missedCurrentQuestion = true;
    _wrongAttempts++;
    _streak = 0;

    setState(() {
      _owlMood = OwlMood.encourage;
      _showHint = true;
      _wrongSelectedIndex = selectedIndex;
      _isWrongCooldown = true;
      if (selectedIndex != null) {
        _disabledWrongIndices.add(selectedIndex);
      }
    });

    _shakeController.forward(from: 0);
    await widget.audioGuide.playWrongSound();
    await widget.audioGuide.speak(
      'Chưa đúng rồi, mình nghe gợi ý rồi thử lại nhé! ${question.hintText}',
    );

    // Tạm khóa nhẹ 1.5 giây để bé Lớp 1 nghe gợi ý thay vì bấm bừa liên thanh.
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      setState(() => _isWrongCooldown = false);
    }
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

  void _checkWordBuild(Question question) {
    if (_builtPieces.length < question.expectedSequence.length) return;
    final built = _builtPieces.join('');
    final expected = question.expectedSequence.join('');
    if (built == expected) {
      _onCorrectAnswer();
    } else {
      _onWrongAnswer();
      Future<void>.delayed(const Duration(milliseconds: 550), () {
        if (mounted) setState(() => _builtPieces.clear());
      });
    }
  }

  String _badgeForType(String type) {
    switch (type) {
      case 'word_build':
        return '🧩 Ghép chữ';
      case 'drag_drop':
        return '🖐️ Kéo thả';
      case 'fill_number':
        return '⌨️ Tự điền';
      case 'visual_count':
        return '🔢 Đếm hình';
      case 'compare_math':
        return '⚖️ So sánh';
      case 'true_false':
        return '✅ Đúng / Sai';
      default:
        return '🎯 Trắc nghiệm';
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveLayout(context);
    final question = widget.questions[_currentIndex];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE6F6FF), Color(0xFFFFFBF2)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.all(r.isCompactPhone ? 12 : 18),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight -
                        (r.isCompactPhone ? 24 : 36),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: r.useSplitLayout ? 1040 : r.maxContentWidth,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHeader(question, r),
                          const SizedBox(height: 12),
                          if (r.useSplitLayout)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildQuestionPanel(question, r),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: _buildInteractiveArea(question, r),
                                ),
                              ],
                            )
                          else ...[
                            _buildQuestionPanel(question, r),
                            SizedBox(height: r.isCompactPhone ? 14 : 20),
                            _buildInteractiveArea(question, r),
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

  Widget _buildHeader(Question question, ResponsiveLayout r) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Câu ${_currentIndex + 1}/${widget.questions.length} • ${question.subject}',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: r.isCompactPhone ? 13.5 : 15,
                ),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (_currentIndex + 1) / widget.questions.length,
                  minHeight: 10,
                  color: const Color(0xFF2EC4B6),
                  backgroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (_streak >= 2)
          Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3B0),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '🔥 $_streak',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        IconButton.filledTonal(
          onPressed: () => _speakQuestionWithOptions(question),
          icon: const Icon(Icons.volume_up_rounded, size: 26),
          tooltip: 'Nghe lại câu hỏi và đáp án',
        ),
      ],
    );
  }

  Widget _buildQuestionPanel(Question question, ResponsiveLayout r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            AnimatedOwlMascot(
              mood: _owlMood,
              size: r.owlQuizSize,
              skin: widget.petState.skin,
              costume: widget.petState.costume,
              accessory: widget.petState.accessory,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _badgeForType(question.type),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1D6FA5),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _owlMood == OwlMood.happy
                          ? 'Tuyệt vời! ${widget.profile.name} giỏi quá 🎉'
                          : (_owlMood == OwlMood.encourage
                              ? 'Cố lên! Xem gợi ý bên dưới nhé 💪'
                              : 'Bạn Cú đang cổ vũ ${widget.profile.name}!'),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: r.isCompactPhone ? 13 : 14.5,
                        color: const Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        AnimatedBuilder(
          animation: _shakeController,
          builder: (context, child) {
            final dx = math.sin(_shakeController.value * math.pi * 4) * 10;
            return Transform.translate(offset: Offset(dx, 0), child: child);
          },
          child: Container(
            padding: EdgeInsets.all(r.isCompactPhone ? 14 : 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _owlMood == OwlMood.happy
                    ? const Color(0xFF2EC4B6)
                    : (_owlMood == OwlMood.encourage
                        ? const Color(0xFFFF8C42)
                        : const Color(0xFFDCEEF8)),
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
                    style: TextStyle(fontSize: r.emojiFontSize),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  question.prompt,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: r.promptFontSize,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_showHint) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4D6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFC857)),
            ),
            child: Row(
              children: [
                const Text('💡', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    question.hintText,
                    style: TextStyle(
                      fontSize: r.isCompactPhone ? 13 : 14.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF7A4E00),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInteractiveArea(Question question, ResponsiveLayout r) {
    switch (question.type) {
      case 'fill_number':
        return _buildNumberPad(r);
      case 'word_build':
        return _buildWordBuildArea(question, r);
      case 'drag_drop':
        return _buildDragDropArea(question, r);
      default:
        return _buildOptionGrid(question, r);
    }
  }

  Widget _buildOptionGrid(Question question, ResponsiveLayout r) {
    final hasLongOption = question.options.any((o) => o.length > 16);
    final crossAxisCount =
        hasLongOption ? 1 : (question.options.length == 3 ? 3 : 2);
    const palette = [
      (Color(0xFF3A86FF), Color(0xFF1E56C5)),
      (Color(0xFFFF8C42), Color(0xFFD16014)),
      (Color(0xFF8338EC), Color(0xFF5A189A)),
      (Color(0xFF00B4D8), Color(0xFF0077B6)),
    ];

    if (crossAxisCount == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(question.options.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildOptionButton(question, index, palette, r),
          );
        }),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: r.isCompactPhone ? 1.85 : 1.7,
      ),
      itemCount: question.options.length,
      itemBuilder: (context, index) =>
          _buildOptionButton(question, index, palette, r),
    );
  }

  Widget _buildOptionButton(
    Question question,
    int index,
    List<(Color, Color)> palette,
    ResponsiveLayout r,
  ) {
    final isWrong =
        _wrongSelectedIndex == index || _disabledWrongIndices.contains(index);
    final isCorrect = _correctSelectedIndex == index;
    final isDisabled = _isWrongCooldown || _disabledWrongIndices.contains(index);
    final baseColor = isCorrect
        ? const Color(0xFF2EC4B6)
        : (isWrong
            ? const Color(0xFFFF6B6B)
            : palette[index % palette.length].$1);
    final shadowColor = isCorrect
        ? const Color(0xFF1A8A7F)
        : (isWrong
            ? const Color(0xFFC92A2A)
            : palette[index % palette.length].$2);

    return AnimatedScale(
      scale: isCorrect ? 1.04 : 1.0,
      duration: const Duration(milliseconds: 160),
      child: Tactile3DButton(
        color: baseColor,
        shadowColor: shadowColor,
        padding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: r.isCompactPhone ? 10 : 14,
        ),
        onPressed: isDisabled
            ? null
            : () {
                if (index == question.correctIndex) {
                  _onCorrectAnswer(selectedIndex: index);
                } else {
                  _onWrongAnswer(selectedIndex: index);
                }
              },
        child: Text(
          question.options[index],
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: r.buttonFontSize,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildWordBuildArea(Question question, ResponsiveLayout r) {
    final targetCount = question.expectedSequence.length;
    final boxW = r.isCompactPhone ? 68.0 : (r.isTablet ? 98.0 : 82.0);
    final boxH = r.isCompactPhone ? 54.0 : 64.0;

    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: List.generate(targetCount, (i) {
            final filled = i < _builtPieces.length ? _builtPieces[i] : '';
            return Container(
              width: boxW,
              height: boxH,
              decoration: BoxDecoration(
                color: filled.isEmpty
                    ? Colors.white
                    : const Color(0xFFE0FBF8),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: filled.isEmpty
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF2EC4B6),
                  width: 2.5,
                ),
              ),
              child: Center(
                child: Text(
                  filled.isEmpty ? '?' : filled,
                  style: TextStyle(
                    fontSize: r.isCompactPhone ? 22 : 26,
                    fontWeight: FontWeight.w900,
                    color: filled.isEmpty
                        ? Colors.grey.shade400
                        : const Color(0xFF0F766E),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: question.options.map((piece) {
            final used = _builtPieces.contains(piece);
            return SizedBox(
              width: r.isCompactPhone ? 94 : 112,
              child: Tactile3DButton(
                color: used ? Colors.grey.shade300 : const Color(0xFF8338EC),
                shadowColor:
                    used ? Colors.grey.shade400 : const Color(0xFF5A189A),
                onPressed: used
                    ? null
                    : () {
                        setState(() => _builtPieces.add(piece));
                        _checkWordBuild(question);
                      },
                child: Text(
                  piece,
                  style: TextStyle(
                    fontSize: r.buttonFontSize + 2,
                    fontWeight: FontWeight.w900,
                    color: used ? Colors.grey : Colors.white,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (_builtPieces.isNotEmpty) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => setState(() => _builtPieces.clear()),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Xếp lại từ đầu'),
          ),
        ],
      ],
    );
  }

  Widget _buildDragDropArea(Question question, ResponsiveLayout r) {
    return Column(
      children: [
        DragTarget<int>(
          onAcceptWithDetails: (details) {
            final idx = details.data;
            setState(() => _droppedAnswer = question.options[idx]);
            if (idx == question.correctIndex) {
              _onCorrectAnswer(selectedIndex: idx);
            } else {
              _onWrongAnswer(selectedIndex: idx);
              Future<void>.delayed(const Duration(milliseconds: 500), () {
                if (mounted) setState(() => _droppedAnswer = null);
              });
            }
          },
          builder: (context, candidateData, rejectedData) {
            final isHovering = candidateData.isNotEmpty;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              height: r.isCompactPhone ? 66 : 78,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: isHovering
                    ? const Color(0xFFD8F3DC)
                    : (_droppedAnswer != null
                        ? const Color(0xFFE0FBF8)
                        : Colors.white),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isHovering
                      ? const Color(0xFF2EC4B6)
                      : const Color(0xFF3A86FF),
                  width: 3,
                ),
              ),
              child: Center(
                child: Text(
                  _droppedAnswer ?? '⬇️ Kéo hoặc chạm đáp án đúng vào đây ⬇️',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: _droppedAnswer != null
                        ? r.buttonFontSize + 3
                        : (r.isCompactPhone ? 14 : 16),
                    fontWeight: FontWeight.w800,
                    color: _droppedAnswer != null
                        ? const Color(0xFF0F766E)
                        : const Color(0xFF3A86FF),
                  ),
                ),
              ),
            );
          },
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: List.generate(question.options.length, (idx) {
            final label = question.options[idx];
            final chip = Container(
              padding: EdgeInsets.symmetric(
                horizontal: r.isCompactPhone ? 16 : 20,
                vertical: r.isCompactPhone ? 11 : 14,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFA94D), Color(0xFFFF8C42)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Color(0xFFD16014), offset: Offset(0, 5)),
                ],
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: r.buttonFontSize,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            );

            return Draggable<int>(
              data: idx,
              feedback: Material(
                color: Colors.transparent,
                child: Transform.scale(scale: 1.08, child: chip),
              ),
              childWhenDragging: Opacity(opacity: 0.35, child: chip),
              child: GestureDetector(
                onTap: () {
                  setState(() => _droppedAnswer = label);
                  if (idx == question.correctIndex) {
                    _onCorrectAnswer(selectedIndex: idx);
                  } else {
                    _onWrongAnswer(selectedIndex: idx);
                    Future<void>.delayed(const Duration(milliseconds: 500), () {
                      if (mounted) setState(() => _droppedAnswer = null);
                    });
                  }
                },
                child: chip,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildNumberPad(ResponsiveLayout r) {
    final keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '⌫', '0', '✓'];
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: r.isCompactPhone ? 8 : 10),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF3A86FF), width: 2.5),
          ),
          child: Text(
            _typedNumber.isEmpty ? 'Bấm số đáp án...' : _typedNumber,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: _typedNumber.isEmpty
                  ? (r.isCompactPhone ? 16 : 18)
                  : (r.isCompactPhone ? 24 : 28),
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
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: r.isCompactPhone ? 2.6 : 2.3,
          ),
          itemCount: keys.length,
          itemBuilder: (context, idx) {
            final label = keys[idx];
            final isSubmit = label == '✓';
            final isBackspace = label == '⌫';
            return Tactile3DButton(
              depth: 4,
              borderRadius: 16,
              padding: const EdgeInsets.symmetric(vertical: 6),
              color: isSubmit
                  ? const Color(0xFF2EC4B6)
                  : (isBackspace
                      ? const Color(0xFFFFD8CC)
                      : Colors.white),
              shadowColor: isSubmit
                  ? const Color(0xFF1A8A7F)
                  : (isBackspace
                      ? const Color(0xFFE07A5F)
                      : const Color(0xFFCBD5E1)),
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
              child: Text(
                label,
                style: TextStyle(
                  fontSize: r.buttonFontSize + 1,
                  fontWeight: FontWeight.w800,
                  color: isSubmit
                      ? Colors.white
                      : (isBackspace
                          ? const Color(0xFFD9480F)
                          : const Color(0xFF1F2937)),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
