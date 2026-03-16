import 'package:flame/extensions.dart';

/// artboard(px) ↔ 화면(px) ↔ forge2d(m) 단위 변환 유틸.
///
/// kPixelPerMeter = 100.0 → 1 forge2d meter = 100 화면 픽셀.
/// TarotGame의 zoom 파라미터와 반드시 동일해야 Flame 렌더링과 물리가 일치.
abstract final class TarotCoordinateUtils {
  /// forge2d world 단위와 화면 픽셀의 변환 비율.
  /// TarotGame(zoom: kPixelPerMeter)과 반드시 동기화.
  static const double kPixelPerMeter = 100.0;

  // ─── 화면(px) ↔ forge2d(m) ──────────────────────────────────────────────

  /// 화면 픽셀 좌표 → forge2d world 좌표(미터)
  static Vector2 screenToWorld(double x, double y) =>
      Vector2(x / kPixelPerMeter, y / kPixelPerMeter);

  /// forge2d world 좌표(미터) → 화면 픽셀 좌표
  static Vector2 worldToScreen(double x, double y) =>
      Vector2(x * kPixelPerMeter, y * kPixelPerMeter);

  // ─── Rive artboard(px) → forge2d(m) ─────────────────────────────────────

  /// Rive artboard 로컬 좌표 → forge2d world 좌표(미터).
  ///
  /// Rive bone.worldTransform의 Mat2D[4], Mat2D[5]를 인자로 전달.
  /// artboard 해상도가 화면 해상도와 다를 경우 screenWidth/Height로 정규화.
  static Vector2 artboardToWorld(
    double artX,
    double artY, {
    required double artboardWidth,
    required double artboardHeight,
    required double screenWidth,
    required double screenHeight,
  }) {
    final screenX = artX / artboardWidth * screenWidth;
    final screenY = artY / artboardHeight * screenHeight;
    return screenToWorld(screenX, screenY);
  }

  /// 화면 크기가 artboard와 동일하다고 가정하는 단순 변환.
  /// artboard 크기 확인 전 임시 사용. Cycle 2에서 artboardToWorld로 교체.
  static Vector2 artboardToWorldSimple(double artX, double artY) =>
      Vector2(artX / kPixelPerMeter, artY / kPixelPerMeter);
}
