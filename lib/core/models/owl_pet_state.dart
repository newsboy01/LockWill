class PetShopItem {
  const PetShopItem({
    required this.id,
    required this.category, // costume | skin | accessory | background | food
    required this.name,
    required this.emoji,
    required this.priceStars,
    this.hungerGain = 0,
    this.happyGain = 0,
  });

  final String id;
  final String category;
  final String name;
  final String emoji;
  final int priceStars;
  final int hungerGain;
  final int happyGain;
}

class PetShopCatalog {
  static const List<PetShopItem> foods = [
    PetShopItem(
      id: 'apple',
      category: 'food',
      name: 'Táo đỏ',
      emoji: '🍎',
      priceStars: 4,
      hungerGain: 22,
      happyGain: 8,
    ),
    PetShopItem(
      id: 'milk',
      category: 'food',
      name: 'Sữa tươi',
      emoji: '🥛',
      priceStars: 5,
      hungerGain: 25,
      happyGain: 10,
    ),
    PetShopItem(
      id: 'cupcake',
      category: 'food',
      name: 'Bánh kem',
      emoji: '🧁',
      priceStars: 8,
      hungerGain: 32,
      happyGain: 18,
    ),
    PetShopItem(
      id: 'fish',
      category: 'food',
      name: 'Cá nướng',
      emoji: '🐟',
      priceStars: 10,
      hungerGain: 45,
      happyGain: 20,
    ),
  ];

  static const List<PetShopItem> costumes = [
    PetShopItem(id: 'none', category: 'costume', name: 'Mặc định', emoji: '🦉', priceStars: 0),
    PetShopItem(id: 'csgt', category: 'costume', name: 'Cảnh sát Giao thông', emoji: '🚦', priceStars: 20),
    PetShopItem(id: 'cscd', category: 'costume', name: 'Cảnh sát Cơ động', emoji: '🛡️', priceStars: 25),
    PetShopItem(id: 'cshs', category: 'costume', name: 'Cảnh sát Hình sự', emoji: '🕵️', priceStars: 25),
    PetShopItem(id: 'army', category: 'costume', name: 'Chú Bộ đội (Quân đội)', emoji: '⭐', priceStars: 25),
    PetShopItem(id: 'doctor', category: 'costume', name: 'Bác sĩ (Y tế)', emoji: '🩺', priceStars: 20),
    PetShopItem(id: 'firefighter', category: 'costume', name: 'Lính Cứu hỏa', emoji: '🚒', priceStars: 25),
    PetShopItem(id: 'astronaut', category: 'costume', name: 'Phi hành gia', emoji: '👩‍🚀', priceStars: 35),
    PetShopItem(id: 'superhero', category: 'costume', name: 'Siêu anh hùng', emoji: '🦸', priceStars: 30),
  ];

  static const List<PetShopItem> skins = [
    PetShopItem(id: 'orange', category: 'skin', name: 'Cú Cam Cổ Điển', emoji: '🟠', priceStars: 0),
    PetShopItem(id: 'snow', category: 'skin', name: 'Cú Tuyết Trắng', emoji: '❄️', priceStars: 20),
    PetShopItem(id: 'galaxy', category: 'skin', name: 'Cú Ngân Hà Tím', emoji: '🌌', priceStars: 35),
    PetShopItem(id: 'gold', category: 'skin', name: 'Cú Hoàng Kim', emoji: '✨', priceStars: 50),
  ];

  static const List<PetShopItem> accessories = [
    PetShopItem(id: 'none', category: 'accessory', name: 'Không phụ kiện', emoji: '➖', priceStars: 0),
    PetShopItem(id: 'grad_cap', category: 'accessory', name: 'Mũ Cử nhân', emoji: '🎓', priceStars: 10),
    PetShopItem(id: 'glasses', category: 'accessory', name: 'Kính Thông minh', emoji: '👓', priceStars: 15),
    PetShopItem(id: 'bowtie', category: 'accessory', name: 'Nơ Đỏ Lịch lãm', emoji: '🎀', priceStars: 12),
    PetShopItem(id: 'crown', category: 'accessory', name: 'Vương miện Vàng', emoji: '👑', priceStars: 30),
  ];

  static const List<PetShopItem> backgrounds = [
    PetShopItem(id: 'cozy', category: 'background', name: 'Phòng ấm áp', emoji: '🏠', priceStars: 0),
    PetShopItem(id: 'forest', category: 'background', name: 'Rừng cổ tích', emoji: '🌲', priceStars: 25),
    PetShopItem(id: 'city', category: 'background', name: 'Thành phố Anh hùng', emoji: '🏙️', priceStars: 30),
    PetShopItem(id: 'space', category: 'background', name: 'Trạm Vũ trụ', emoji: '🚀', priceStars: 40),
  ];
}

class OwlPetState {
  const OwlPetState({
    this.hunger = 80,
    this.hygiene = 85,
    this.energy = 85,
    this.happiness = 90,
    this.xp = 0,
    this.level = 1,
    this.skin = 'orange',
    this.costume = 'none',
    this.accessory = 'grad_cap',
    this.background = 'cozy',
    this.ownedSkins = const ['orange'],
    this.ownedCostumes = const ['none'],
    this.ownedAccessories = const ['none', 'grad_cap'],
    this.ownedBackgrounds = const ['cozy'],
    this.lastUpdatedMillis = 0,
  });

  final int hunger; // 0..100
  final int hygiene; // 0..100
  final int energy; // 0..100
  final int happiness; // 0..100
  final int xp;
  final int level;
  final String skin;
  final String costume;
  final String accessory;
  final String background;
  final List<String> ownedSkins;
  final List<String> ownedCostumes;
  final List<String> ownedAccessories;
  final List<String> ownedBackgrounds;
  final int lastUpdatedMillis;

  String get titleByLevel {
    if (level >= 10) return 'Siêu Cú Vũ Trụ';
    if (level >= 6) return 'Cú Thông Thái';
    if (level >= 3) return 'Cú Tiểu Học';
    return 'Cú Con Đáng Yêu';
  }

  OwlPetState addXp(int gainedXp) {
    var nextXp = xp + gainedXp;
    var nextLevel = level;
    while (nextXp >= nextLevel * 50) {
      nextXp -= nextLevel * 50;
      nextLevel++;
    }
    return copyWith(xp: nextXp, level: nextLevel);
  }

  /// Giảm nhẹ các chỉ số theo thời gian thực (mỗi 1 giờ giảm nhẹ để bé nhớ chăm Cú).
  OwlPetState applyTimeDecay(int nowMillis) {
    if (lastUpdatedMillis <= 0) {
      return copyWith(lastUpdatedMillis: nowMillis);
    }
    final hours = ((nowMillis - lastUpdatedMillis) / 3600000.0).floor();
    if (hours <= 0) return this;
    final drop = (hours * 4).clamp(0, 45);
    return copyWith(
      hunger: (hunger - drop).clamp(15, 100),
      hygiene: (hygiene - (drop ~/ 2)).clamp(20, 100),
      energy: (energy - (drop ~/ 2)).clamp(20, 100),
      happiness: (happiness - (drop ~/ 2)).clamp(25, 100),
      lastUpdatedMillis: nowMillis,
    );
  }

  OwlPetState copyWith({
    int? hunger,
    int? hygiene,
    int? energy,
    int? happiness,
    int? xp,
    int? level,
    String? skin,
    String? costume,
    String? accessory,
    String? background,
    List<String>? ownedSkins,
    List<String>? ownedCostumes,
    List<String>? ownedAccessories,
    List<String>? ownedBackgrounds,
    int? lastUpdatedMillis,
  }) {
    return OwlPetState(
      hunger: (hunger ?? this.hunger).clamp(0, 100),
      hygiene: (hygiene ?? this.hygiene).clamp(0, 100),
      energy: (energy ?? this.energy).clamp(0, 100),
      happiness: (happiness ?? this.happiness).clamp(0, 100),
      xp: xp ?? this.xp,
      level: level ?? this.level,
      skin: skin ?? this.skin,
      costume: costume ?? this.costume,
      accessory: accessory ?? this.accessory,
      background: background ?? this.background,
      ownedSkins: ownedSkins ?? this.ownedSkins,
      ownedCostumes: ownedCostumes ?? this.ownedCostumes,
      ownedAccessories: ownedAccessories ?? this.ownedAccessories,
      ownedBackgrounds: ownedBackgrounds ?? this.ownedBackgrounds,
      lastUpdatedMillis: lastUpdatedMillis ?? this.lastUpdatedMillis,
    );
  }

  Map<String, dynamic> toJson() => {
        'hunger': hunger,
        'hygiene': hygiene,
        'energy': energy,
        'happiness': happiness,
        'xp': xp,
        'level': level,
        'skin': skin,
        'costume': costume,
        'accessory': accessory,
        'background': background,
        'ownedSkins': ownedSkins,
        'ownedCostumes': ownedCostumes,
        'ownedAccessories': ownedAccessories,
        'ownedBackgrounds': ownedBackgrounds,
        'lastUpdatedMillis': lastUpdatedMillis,
      };

  factory OwlPetState.fromJson(Map<String, dynamic> json) {
    return OwlPetState(
      hunger: (json['hunger'] as int?) ?? 80,
      hygiene: (json['hygiene'] as int?) ?? 85,
      energy: (json['energy'] as int?) ?? 85,
      happiness: (json['happiness'] as int?) ?? 90,
      xp: (json['xp'] as int?) ?? 0,
      level: (json['level'] as int?) ?? 1,
      skin: (json['skin'] as String?) ?? 'orange',
      costume: (json['costume'] as String?) ?? 'none',
      accessory: (json['accessory'] as String?) ?? 'grad_cap',
      background: (json['background'] as String?) ?? 'cozy',
      ownedSkins: List<String>.from(
        (json['ownedSkins'] as List<dynamic>?) ?? const ['orange'],
      ),
      ownedCostumes: List<String>.from(
        (json['ownedCostumes'] as List<dynamic>?) ?? const ['none'],
      ),
      ownedAccessories: List<String>.from(
        (json['ownedAccessories'] as List<dynamic>?) ??
            const ['none', 'grad_cap'],
      ),
      ownedBackgrounds: List<String>.from(
        (json['ownedBackgrounds'] as List<dynamic>?) ?? const ['cozy'],
      ),
      lastUpdatedMillis: (json['lastUpdatedMillis'] as int?) ?? 0,
    );
  }
}
