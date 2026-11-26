import 'package:flutter/material.dart';

/// Bộ tính toán kích thước thích ứng cho mọi loại thiết bị:
/// - Điện thoại nhỏ (< 360dp hoặc màn hình thấp < 680dp)
/// - Điện thoại tiêu chuẩn (360dp - 599dp)
/// - Máy tính bảng / Tablet (shortestSide >= 600dp) và chế độ xoay ngang (Landscape)
class ResponsiveLayout {
  ResponsiveLayout(BuildContext context)
      : size = MediaQuery.sizeOf(context),
        padding = MediaQuery.paddingOf(context);

  final Size size;
  final EdgeInsets padding;

  double get width => size.width;
  double get height => size.height;
  double get shortestSide => size.shortestSide;

  bool get isTablet => shortestSide >= 600;
  bool get isLandscape => width > height;
  bool get isCompactPhone => !isTablet && (width < 360 || height < 680);
  bool get useSplitLayout => (isTablet && isLandscape) || (width >= 760 && isLandscape);

  /// Chiều rộng nội dung tối đa để giao diện không bị kéo giãn quá rộng trên Tablet.
  double get maxContentWidth => isTablet ? 780 : 520;

  double get pagePadding {
    if (isTablet) return 28;
    if (isCompactPhone) return 14;
    return 20;
  }

  double get owlHeroSize {
    if (isTablet) return isLandscape ? 185 : 200;
    if (isCompactPhone) return 120;
    return 155;
  }

  double get owlQuizSize {
    if (isTablet) return 90;
    if (isCompactPhone) return 58;
    return 72;
  }

  double get titleFontSize {
    if (isTablet) return 30;
    if (isCompactPhone) return 21;
    return 25;
  }

  double get bodyFontSize {
    if (isTablet) return 19;
    if (isCompactPhone) return 14.5;
    return 16.5;
  }

  double get promptFontSize {
    if (isTablet) return 24;
    if (isCompactPhone) return 17.5;
    return 20;
  }

  double get emojiFontSize {
    if (isTablet) return 38;
    if (isCompactPhone) return 26;
    return 32;
  }

  double get buttonFontSize {
    if (isTablet) return 21;
    if (isCompactPhone) return 16;
    return 18.5;
  }
}
