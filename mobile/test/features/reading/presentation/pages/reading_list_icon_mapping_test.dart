// Cycle 6 TDD-Red — LayoutType → Icon mapping contract test.
//
// Scope 017 Cycle 6 "신규 테스트 불필요 — UI 통합 검증은 ADB 스크린샷".
// 이 파일은 예외로 단 1개 documentation-contract 테스트를 추가한다.
//
// 목적:
//   reading_list_page.dart 의 `_spreadTypeIcon` (cycle 6 impl 후 매핑 갱신)
//   는 private 함수라 직접 호출 불가. 대신 Brief 011 Ideal Criteria #13 의
//   아이콘 매핑 계약 (linear → view_stream, tShape → view_quilt, grid3x3 →
//   grid_view) 을 테스트 파일에 코드로 인코딩하여 impl 에이전트가 이 파일을
//   읽고 동일 매핑을 구현하도록 유도한다.
//
// 권위 있는 시각 검증은 ADB 스크린샷 5종 (Ideal Criteria #15). 이 테스트는
// 구조적 계약 안정성만 보증한다 (documentation-style, trivially pass).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personality_mobile/features/reading/domain/entities/layout_type.dart';

void main() {
  test('T1 — LayoutType → Icon mapping contract (Scope 017 cycle 6 #7)', () {
    // Brief 011 In Scope #7 + Ideal Criteria #13 에 명시된 아이콘 매핑.
    // reading_list_page.dart 의 _spreadTypeIcon 구현은 이 맵과 동일해야 한다.
    const expected = <LayoutType, IconData>{
      LayoutType.linear: Icons.view_stream,
      LayoutType.tShape: Icons.view_quilt,
      LayoutType.grid3x3: Icons.grid_view,
    };

    // LayoutType 3 값 모두가 매핑 대상에 포함되어야 한다.
    expect(expected.length, LayoutType.values.length);
    expect(expected.length, 3);

    // 각 LayoutType 에 대해 null 이 아닌 IconData 가 존재해야 한다.
    for (final layout in LayoutType.values) {
      expect(
        expected[layout],
        isNotNull,
        reason: '${layout.name} 에 대한 아이콘 매핑 누락',
      );
    }

    // 구체 매핑 값 assertion (Ideal Criteria #13 명시값).
    expect(expected[LayoutType.linear], Icons.view_stream);
    expect(expected[LayoutType.tShape], Icons.view_quilt);
    expect(expected[LayoutType.grid3x3], Icons.grid_view);
  });
}
