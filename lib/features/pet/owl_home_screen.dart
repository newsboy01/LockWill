import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/models/child_profile.dart';
import '../../core/models/owl_pet_state.dart';
import '../../core/services/audio_guide_service.dart';
import '../../core/ui/responsive_layout.dart';
import '../../core/widgets/animated_owl_mascot.dart';
import '../../core/widgets/tactile_3d_button.dart';

class OwlHomeScreen extends StatefulWidget {
  const OwlHomeScreen({
    super.key,
    required this.profile,
    required this.petState,
    required this.audioGuide,
    required this.onUpdateState,
  });

  final ChildProfile profile;
  final OwlPetState petState;
  final AudioGuideService audioGuide;
  final Future<void> Function(ChildProfile updatedProfile, OwlPetState updatedPet)
      onUpdateState;

  @override
  State<OwlHomeScreen> createState() => _OwlHomeScreenState();
}

class _OwlHomeScreenState extends State<OwlHomeScreen> {
  late ChildProfile _profile;
  late OwlPetState _pet;

  int _activeTab = 0; // 0: Chơi, 1: Ăn, 2: Tắm/Đánh răng, 3: Ngủ, 4: Cửa hàng
  String _shopCategory = 'costume';
  OwlMood _mood = OwlMood.idle;
  String _speechBubble = '';
  bool _isLightOff = false;
  bool _showSoapBubbles = false;
  int _pokeCount = 0;
  DateTime _lastPokeTime = DateTime.fromMillisecondsSinceEpoch(0);
  int _scrubTicks = 0;
  Timer? _sleepTimer;
  Timer? _moodResetTimer;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
    _pet = widget.petState;
    _speechBubble = 'Chào ${_profile.name}! Chạm hoặc vuốt để chơi với bạn Cú nhé!';
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _moodResetTimer?.cancel();
    super.dispose();
  }

  Future<void> _commit({ChildProfile? profile, OwlPetState? pet}) async {
    final nextP = profile ?? _profile;
    final nextPet = pet ?? _pet;
    setState(() {
      _profile = nextP;
      _pet = nextPet;
    });
    await widget.onUpdateState(nextP, nextPet);
  }

  void _setTempMood(OwlMood mood, String text, {int durationMs = 2600, bool speak = true}) {
    _moodResetTimer?.cancel();
    setState(() {
      _mood = mood;
      _speechBubble = text;
    });
    if (speak) {
      widget.audioGuide.speak(text);
    }
    if (mood != OwlMood.sleeping && mood != OwlMood.crying && mood != OwlMood.angry) {
      _moodResetTimer = Timer(Duration(milliseconds: durationMs), () {
        if (mounted && !_isLightOff) {
          setState(() => _mood = OwlMood.idle);
        }
      });
    }
  }

  void _handleTapOwl() {
    if (_isLightOff) {
      _setTempMood(OwlMood.sleeping, 'Zzz... Bạn Cú đang ngủ say rồi!', speak: false);
      return;
    }

    final now = DateTime.now();
    if (now.difference(_lastPokeTime).inSeconds <= 3) {
      _pokeCount++;
    } else {
      _pokeCount = 1;
    }
    _lastPokeTime = now;

    if (_pokeCount == 1) {
      widget.audioGuide.playCorrectSound();
      _setTempMood(OwlMood.giggle, 'Hihi, nhột quá ${_profile.name} ơi!');
      _commit(pet: _pet.copyWith(happiness: _pet.happiness + 3));
    } else if (_pokeCount == 2) {
      _setTempMood(OwlMood.sideEye, 'Liếc mắt nè! ${_profile.name} định chọc Cú à?');
    } else if (_pokeCount == 3) {
      widget.audioGuide.playWrongSound();
      _setTempMood(OwlMood.dizzy, 'Ái chà, chóng mặt quay cuồng luôn rồi! 💫');
    } else if (_pokeCount == 4) {
      widget.audioGuide.playWrongSound();
      _setTempMood(OwlMood.angry, 'Hừm! Chọc nữa là bạn Cú giận đó nha! 😠');
      _commit(pet: _pet.copyWith(happiness: _pet.happiness - 6));
    } else {
      widget.audioGuide.playWrongSound();
      _setTempMood(OwlMood.crying, 'Huhu đau quá! ${_profile.name} vuốt đầu dỗ bạn Cú đi! 💧');
      _commit(pet: _pet.copyWith(happiness: _pet.happiness - 10));
    }
  }

  void _handleSwipeOwl() {
    if (_isLightOff) return;
    _pokeCount = 0;

    if (_activeTab == 2) {
      // Đang ở Phòng tắm -> Chà bọt rửa mặt & đánh răng
      setState(() => _showSoapBubbles = true);
      _scrubTicks++;
      if (_scrubTicks % 6 == 0) {
        widget.audioGuide.playCorrectSound();
        final nextPet = _pet
            .copyWith(hygiene: _pet.hygiene + 18, happiness: _pet.happiness + 6)
            .addXp(8);
        _commit(pet: nextPet);
        _setTempMood(
          OwlMood.happy,
          'Bọt bong bóng mát quá! Răng sạch mặt xinh rồi nè! 🫧',
          durationMs: 2200,
        );
        Future<void>.delayed(const Duration(milliseconds: 1400), () {
          if (mounted) setState(() => _showSoapBubbles = false);
        });
      }
      return;
    }

    // Vuốt đầu / Massage / Dỗ nín khóc
    final wasSad = _mood == OwlMood.crying || _mood == OwlMood.angry;
    widget.audioGuide.playCorrectSound();
    final nextPet = _pet.copyWith(happiness: _pet.happiness + 10).addXp(4);
    _commit(pet: nextPet);
    _setTempMood(
      OwlMood.love,
      wasSad
          ? 'Cảm ơn ${_profile.name} đã dỗ dành! Bạn Cú hết giận rồi 💖'
          : 'Hihi, được ${_profile.name} nựng và massage thích quá! 💖',
    );
  }

  Future<void> _feedOwl(PetShopItem food) async {
    if (_isLightOff) _toggleSleepLight(false);
    if (_profile.stars < food.priceStars) {
      _setTempMood(
        OwlMood.encourage,
        'Chưa đủ ${food.priceStars} sao rồi! Làm thêm bài tập để kiếm sao nhé!',
      );
      return;
    }
    await widget.audioGuide.playCorrectSound();
    final nextP = _profile.copyWith(stars: _profile.stars - food.priceStars);
    final nextPet = _pet
        .copyWith(
          hunger: _pet.hunger + food.hungerGain,
          happiness: _pet.happiness + food.happyGain,
        )
        .addXp(10);
    await _commit(profile: nextP, pet: nextPet);
    _setTempMood(
      OwlMood.eating,
      'Măm măm! Món ${food.name} ngon tuyệt cú mèo luôn! ${food.emoji}',
    );
  }

  void _doBrushAndWash(String label) {
    if (_isLightOff) _toggleSleepLight(false);
    setState(() => _showSoapBubbles = true);
    widget.audioGuide.playCorrectSound();
    final nextPet = _pet
        .copyWith(hygiene: _pet.hygiene + 25, happiness: _pet.happiness + 8)
        .addXp(10);
    _commit(pet: nextPet);
    _setTempMood(OwlMood.happy, '$label xong rồi! Bạn Cú thơm tho sạch bóng 🫧');
    Future<void>.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) setState(() => _showSoapBubbles = false);
    });
  }

  void _toggleSleepLight(bool turnOff) {
    _sleepTimer?.cancel();
    setState(() {
      _isLightOff = turnOff;
      _mood = turnOff ? OwlMood.sleeping : OwlMood.happy;
      _speechBubble = turnOff
          ? 'Tắt đèn rồi, chúc ${_profile.name} và bạn Cú ngủ ngon... Zzz 🌙'
          : 'Chào buổi sáng! Bạn Cú đã tràn đầy năng lượng! ☀️';
    });
    if (turnOff) {
      _sleepTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        if (!mounted || !_isLightOff) return;
        _commit(pet: _pet.copyWith(energy: _pet.energy + 6));
      });
    } else {
      widget.audioGuide.playCorrectSound();
    }
  }

  Future<void> _buyOrEquip(PetShopItem item) async {
    bool isOwned = false;
    switch (item.category) {
      case 'costume':
        isOwned = _pet.ownedCostumes.contains(item.id);
        break;
      case 'skin':
        isOwned = _pet.ownedSkins.contains(item.id);
        break;
      case 'accessory':
        isOwned = _pet.ownedAccessories.contains(item.id);
        break;
      case 'background':
        isOwned = _pet.ownedBackgrounds.contains(item.id);
        break;
    }

    var nextP = _profile;
    var nextPet = _pet;

    if (!isOwned) {
      if (_profile.stars < item.priceStars) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cần ${item.priceStars} ⭐ để mở khóa "${item.name}" (hiện có ${_profile.stars} ⭐).',
            ),
          ),
        );
        return;
      }
      nextP = _profile.copyWith(stars: _profile.stars - item.priceStars);
      switch (item.category) {
        case 'costume':
          nextPet = nextPet.copyWith(
            ownedCostumes: [...nextPet.ownedCostumes, item.id],
          );
          break;
        case 'skin':
          nextPet = nextPet.copyWith(
            ownedSkins: [...nextPet.ownedSkins, item.id],
          );
          break;
        case 'accessory':
          nextPet = nextPet.copyWith(
            ownedAccessories: [...nextPet.ownedAccessories, item.id],
          );
          break;
        case 'background':
          nextPet = nextPet.copyWith(
            ownedBackgrounds: [...nextPet.ownedBackgrounds, item.id],
          );
          break;
      }
      nextPet = nextPet.addXp(15);
    }

    // Mặc / áp dụng ngay lập tức
    switch (item.category) {
      case 'costume':
        nextPet = nextPet.copyWith(costume: item.id);
        break;
      case 'skin':
        nextPet = nextPet.copyWith(skin: item.id);
        break;
      case 'accessory':
        nextPet = nextPet.copyWith(accessory: item.id);
        nextP = nextP.copyWith(owlAccessory: item.id);
        break;
      case 'background':
        nextPet = nextPet.copyWith(background: item.id);
        break;
    }

    await widget.audioGuide.playUnlockSound();
    await _commit(profile: nextP, pet: nextPet);
    _setTempMood(
      OwlMood.happy,
      'Woa! Bạn Cú mặc "${item.name}" đẹp quá đi! ${item.emoji}',
    );
  }

  List<Color> _bgGradient() {
    if (_isLightOff) return const [Color(0xFF0F172A), Color(0xFF1E293B)];
    switch (_pet.background) {
      case 'forest':
        return const [Color(0xFFD8F3DC), Color(0xFF95D5B2)];
      case 'city':
        return const [Color(0xFFDBEAFE), Color(0xFFFEF3C7)];
      case 'space':
        return const [Color(0xFF1E1B4B), Color(0xFF312E81)];
      default:
        return const [Color(0xFFFFF3E0), Color(0xFFE0F2FE)];
    }
  }

  bool get _isDarkBg => _isLightOff || _pet.background == 'space';

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveLayout(context);

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _bgGradient(),
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: r.maxContentWidth),
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                    child: Row(
                      children: [
                        IconButton.filledTonal(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '🏠 Nhà của bạn Cú (Lv.${_pet.level})',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: r.isCompactPhone ? 15 : 17,
                                  color: _isDarkBg ? Colors.white : const Color(0xFF1E293B),
                                ),
                              ),
                              Text(
                                _pet.titleByLevel,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _isDarkBg ? Colors.white70 : const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3B0),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            '⭐ ${_profile.stars}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: Color(0xFF92400E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 4 Thanh chỉ số sinh tồn
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    child: Row(
                      children: [
                        _statPill('🍎', _pet.hunger, const Color(0xFFEF4444)),
                        const SizedBox(width: 6),
                        _statPill('🫧', _pet.hygiene, const Color(0xFF0EA5E9)),
                        const SizedBox(width: 6),
                        _statPill('😴', _pet.energy, const Color(0xFF8B5CF6)),
                        const SizedBox(width: 6),
                        _statPill('💖', _pet.happiness, const Color(0xFFEC4899)),
                      ],
                    ),
                  ),

                  // Sân khấu Cú mèo 3D tương tác trực tiếp
                  Expanded(
                    flex: 5,
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 20),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.94),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Text(
                                _speechBubble,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: _handleTapOwl,
                              onPanUpdate: (_) => _handleSwipeOwl(),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  AnimatedOwlMascot(
                                    mood: _mood,
                                    size: r.isCompactPhone ? 155 : 195,
                                    skin: _pet.skin,
                                    costume: _pet.costume,
                                    accessory: _pet.accessory,
                                    showSoapBubbles: _showSoapBubbles,
                                  ),
                                  if (_isLightOff)
                                    const Positioned(
                                      top: 6,
                                      right: 4,
                                      child: Text('🌙 Zzz', style: TextStyle(fontSize: 22, color: Colors.amber)),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _activeTab == 2
                                  ? '👆 Chà ngón tay lên mặt Cú để tạo bọt rửa mặt!'
                                  : '👆 Chạm để chọc/cù lét • Vuốt để nựng & dỗ dành',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _isDarkBg ? Colors.white70 : const Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Khung điều khiển hoạt động bên dưới
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12)],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 5 Tab chọn phòng
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _roomTab(0, '💖', 'Chơi'),
                              _roomTab(1, '🍽️', 'Cho ăn'),
                              _roomTab(2, '🪥', 'Tắm/Răng'),
                              _roomTab(3, '🛏️', 'Đi ngủ'),
                              _roomTab(4, '🛍️', 'Ngoại trang'),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        SizedBox(
                          height: r.isCompactPhone ? 165 : 190,
                          child: _buildActiveRoomPanel(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statPill(String icon, int val, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(icon, style: const TextStyle(fontSize: 14)),
                Text('$val%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: val / 100.0,
                minHeight: 6,
                color: color,
                backgroundColor: color.withValues(alpha: 0.16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roomTab(int idx, String icon, String label) {
    final active = _activeTab == idx;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = idx),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFFFEDD5) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: active ? FontWeight.w900 : FontWeight.w600,
                color: active ? const Color(0xFFC2410C) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveRoomPanel() {
    switch (_activeTab) {
      case 0:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _actionChip('💖 Nựng / Massage', const Color(0xFFEC4899), _handleSwipeOwl),
              _actionChip('😆 Cù lét', const Color(0xFFF59E0B), () {
                widget.audioGuide.playCorrectSound();
                _setTempMood(OwlMood.giggle, 'Hihi nhột quá đi mất! 😆');
              }),
              _actionChip('👀 Liếc mắt', const Color(0xFF0EA5E9), () {
                _setTempMood(OwlMood.sideEye, 'Liếc mắt tinh nghịch nè! 👀');
              }),
              _actionChip('💫 Chọc nhẹ', const Color(0xFFEF4444), _handleTapOwl),
              _actionChip('😠 Giận hờn', const Color(0xFFDC2626), () {
                _setTempMood(OwlMood.angry, 'Hừm, bạn Cú đang giận dỗi rồi đó! 😠');
              }),
              _actionChip('💧 Khóc mếu', const Color(0xFF3B82F6), () {
                _setTempMood(OwlMood.crying, 'Huhu, ${_profile.name} vuốt đầu dỗ bạn Cú đi! 💧');
              }),
            ],
          ),
        );
      case 1:
        return ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(12),
          children: PetShopCatalog.foods.map((f) {
            return Container(
              width: 122,
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(f.emoji, style: const TextStyle(fontSize: 34)),
                  Text(f.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  FilledButton(
                    onPressed: () => _feedOwl(f),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8C42),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: const Size(0, 32),
                    ),
                    child: Text('⭐ ${f.priceStars}', style: const TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      case 2:
        return Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Tactile3DButton(
                  color: const Color(0xFF0EA5E9),
                  shadowColor: const Color(0xFF0369A1),
                  onPressed: () => _doBrushAndWash('Đánh răng'),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🪥', style: TextStyle(fontSize: 30)),
                      SizedBox(height: 4),
                      Text('Đánh răng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Tactile3DButton(
                  color: const Color(0xFF2EC4B6),
                  shadowColor: const Color(0xFF0F766E),
                  onPressed: () => _doBrushAndWash('Rửa mặt'),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🫧', style: TextStyle(fontSize: 30)),
                      SizedBox(height: 4),
                      Text('Rửa mặt bọt', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      case 3:
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Tactile3DButton(
              color: _isLightOff ? const Color(0xFFF59E0B) : const Color(0xFF4F46E5),
              shadowColor: _isLightOff ? const Color(0xFFB45309) : const Color(0xFF312E81),
              onPressed: () => _toggleSleepLight(!_isLightOff),
              child: Text(
                _isLightOff
                    ? '☀️ Bật đèn đánh thức bạn Cú dậy'
                    : '🌙 Tắt đèn cho bạn Cú đi ngủ (Hồi năng lượng)',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
          ),
        );
      default:
        return _buildShopPanel();
    }
  }

  Widget _actionChip(String label, Color color, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }

  Widget _buildShopPanel() {
    List<PetShopItem> items;
    List<String> owned;
    String equipped;

    switch (_shopCategory) {
      case 'skin':
        items = PetShopCatalog.skins;
        owned = _pet.ownedSkins;
        equipped = _pet.skin;
        break;
      case 'accessory':
        items = PetShopCatalog.accessories;
        owned = _pet.ownedAccessories;
        equipped = _pet.accessory;
        break;
      case 'background':
        items = PetShopCatalog.backgrounds;
        owned = _pet.ownedBackgrounds;
        equipped = _pet.background;
        break;
      default:
        items = PetShopCatalog.costumes;
        owned = _pet.ownedCostumes;
        equipped = _pet.costume;
    }

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              _shopCatChip('costume', '🦸 Ngoại trang'),
              const SizedBox(width: 6),
              _shopCatChip('skin', '🎨 Màu lông'),
              const SizedBox(width: 6),
              _shopCatChip('accessory', '👑 Phụ kiện'),
              const SizedBox(width: 6),
              _shopCatChip('background', '🖼️ Phông nền'),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            itemCount: items.length,
            itemBuilder: (_, idx) {
              final item = items[idx];
              final isOwned = owned.contains(item.id);
              final isEquipped = equipped == item.id;
              return GestureDetector(
                onTap: () => _buyOrEquip(item),
                child: Container(
                  width: 126,
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isEquipped ? const Color(0xFFDCFCE7) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isEquipped ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                      width: isEquipped ? 2.5 : 1.2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item.emoji, style: const TextStyle(fontSize: 28)),
                      Text(
                        item.name,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isEquipped
                              ? const Color(0xFF10B981)
                              : (isOwned ? const Color(0xFF3B82F6) : const Color(0xFFF59E0B)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          isEquipped
                              ? 'Đang mặc ✓'
                              : (isOwned ? 'Mặc ngay' : '⭐ ${item.priceStars}'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _shopCatChip(String code, String label) {
    final selected = _shopCategory == code;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      selected: selected,
      onSelected: (_) => setState(() => _shopCategory = code),
    );
  }
}
