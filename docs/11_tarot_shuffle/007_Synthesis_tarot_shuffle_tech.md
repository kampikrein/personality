---
id: "007"
title: "타로 셔플 앱 기술 스택 — Synthesis Report"
category: report
status: archived
created: 2026-03-15
summary: >
  4개 관점(셔플 엔진, 센서/난수, 데이터, 아키텍처)의 병렬 조사 결과 종합.
  하이브리드 셔플 엔진(순수 Flutter + Flame), 이원화 상태 관리(Riverpod + 게임 루프),
  Drift + freezed 데이터 계층, sensors_plus + FortunaRandom 엔트로피 시스템으로 수렴.
keywords: [parallel-synthesis, research, flutter, tarot, shuffle, tech-stack]
modules: [mobile]
---

# 타로 셔플 앱 기술 스택 — Synthesis Report

## Team Composition & Individual Reports

| # | 관점 | Agent Type | Report | Status |
|---|------|-----------|--------|--------|
| 1 | 셔플 엔진 & 카드 애니메이션 | general-purpose | [003_Agent_shuffle_engine.md](./003_Agent_shuffle_engine.md) | complete |
| 2 | 센서 통합 & 난수 생성 | general-purpose | [004_Agent_sensor_rng.md](./004_Agent_sensor_rng.md) | complete |
| 3 | 데이터 아키텍처 & 오프라인 | general-purpose | [005_Agent_data_offline.md](./005_Agent_data_offline.md) | complete |
| 4 | Flutter 앱 아키텍처 & 프로젝트 구조 | general-purpose | [006_Agent_architecture.md](./006_Agent_architecture.md) | complete |

---

## Cross-Analysis

### Common Findings

1. **CustomPainter가 핵심 렌더링 전략** — 관점 1(셔플 엔진)과 관점 4(아키텍처) 모두 위젯 방식(~400개 한계)이 아닌 Canvas 직접 그리기를 권장. 78장 카드의 개별 상태를 매 프레임 paint()에서 순회하는 방식으로 수렴.

2. **freezed 통일 채택** — 관점 3(데이터 모델: Dart 불변 객체 + json_serializable)과 관점 4(아키텍처: Entity/Model 분리)에서 독립적으로 freezed를 권장. 코드 생성 기반 직렬화와 패턴 매칭 지원.

3. **오프라인-퍼스트 ↔ Repository 패턴 자연 정합** — 관점 3의 Drift 로컬 DB + sync_queue 설계가 관점 4의 Clean Architecture Repository 패턴과 완벽 정합. DeckRepository가 로컬/원격 데이터소스를 추상화하는 구조.

4. **게임 루프 패러다임** — 관점 1(Flame GameWidget)과 관점 4(Ticker + CustomPainter)가 독립적으로 "위젯 트리 리빌드를 스킵하고 paint만 호출" 패턴으로 수렴. 애니메이션 상태는 리액티브 스트림이 아닌 프레임 단위 업데이트가 적합.

### Conflicting Opinions

1. **Flame 도입 범위**
   - 관점 1: 워시 셔플에만 Flame+Forge2D 도입, 나머지는 순수 Flutter
   - 관점 4: 애니메이션 상태 전체를 게임 루프(Ticker+CustomPainter)로 분리
   - **판단**: 관점 1의 하이브리드 접근이 현실적. Flame은 GameWidget으로 특정 화면에만 임베드. 리플/오버핸드는 AnimationController로 충분하며, Flame 의존성을 최소화하는 것이 유지보수에 유리. 단, 관점 4의 "CustomPainter repaint Listenable" 패턴은 순수 Flutter 셔플에도 적용 가능.

2. **이미지 관리: 스프라이트 시트 vs 개별 이미지**
   - 관점 1: 78장을 단일 스프라이트 시트(텍스처 아틀라스)로 병합 → drawAtlas() 단일 호출
   - 관점 3: 커스텀 덱은 사용자가 개별 이미지를 업로드 → 파일시스템 개별 관리
   - **판단**: 기본 내장 덱(RWS)은 스프라이트 시트로 최적화. 커스텀 덱은 개별 이미지 + precacheImage + cacheWidth/cacheHeight로 메모리 최적화. 두 전략 공존이 필요.

3. **센서 데이터 ↔ 물리 엔진 연결**
   - 관점 2: 센서 → 엔트로피 풀 → CSPRNG 시드 → Fisher-Yates 셔플 (난수 경로)
   - 관점 1: 센서 강도 → 오버핸드 청크 크기, 워시 카드 속도/방향 (물리 경로)
   - **판단**: 두 경로는 상호 배타적이 아님. 센서 데이터는 (1) 난수 시드와 (2) 애니메이션 파라미터 양쪽에 동시에 사용. SensorDataCollector가 수집한 데이터를 EntropyPool과 AnimationParameterMapper 양쪽에 분배.

### Synergy Effects

1. **Strategy 패턴 + Flame GameWidget 전환**: 관점 4의 Strategy 인터페이스(`ShuffleStrategy`)가 관점 1의 기술 스택 분기를 자연스럽게 흡수. `RiffleShuffleStrategy`는 AnimationController를, `WashShuffleStrategy`는 Flame GameWidget을 내부적으로 사용하되, 외부 인터페이스는 동일.

2. **Forge2D ContactListener + 햅틱**: 관점 1의 Forge2D 충돌 감지(ContactListener)가 관점 2의 햅틱 피드백 트리거와 직접 연결. 충돌 이벤트 → HapticFeedback.selectionClick() 호출 (50ms 쓰로틀링).

3. **Drift TypeConverter + freezed**: 관점 3의 Drift JSON1 확장 + TypeConverter가 관점 4의 freezed 불변 모델과 결합. `meanings` 필드의 JSON 컬럼 ↔ `CardMeanings` freezed 객체 자동 변환.

---

## Comprehensive Conclusion

4개 관점의 조사 결과, Flutter 타로 셔플 앱의 기술 스택은 높은 수준의 일관성으로 수렴하였다.

### Key Findings

1. **하이브리드 셔플 엔진이 유일한 현실적 해법** — 리플/오버핸드(사전 정의 경로)와 워시(동적 물리 충돌)는 근본적으로 다른 렌더링 패러다임을 요구. 하나의 기술로 통합하면 과잉 설계(순수 Flutter) 또는 과잉 의존(Flame 전체 도입) 중 하나가 됨.

2. **이원화 상태 관리가 핵심 아키텍처 결정** — Riverpod(앱 상태) + 게임 루프(애니메이션 상태) 분리. 매 프레임 78개 카드 상태를 Riverpod/BLoC으로 전파하면 위젯 트리 rebuild 오버헤드로 60fps 불가.

3. **PRD의 센서 엔트로피 모델은 기술적으로 실현 가능하나 설계 변경 필요** — `Random.secure()`는 외부 시드 주입 불가. PointyCastle FortunaRandom으로 대체하고, SHA-256 누적 해시로 엔트로피 풀을 구성하여 센서 데이터를 주입하는 구조로 재설계.

4. **Drift가 데이터 계층의 유일한 합리적 선택** — 관계형 쿼리(덱-카드 FK) + JSON1 확장(meanings 필드) + 타입 안전 + 리액티브 스트림 + 마이그레이션이 모두 필요한 요구사항에서 대안 부재. Isar는 유지보수 불확실.

5. **성능 낙관 가능** — Impeller(AOT 셰이더), CustomPainter(위젯 트리 스킵), 스프라이트 시트(draw call 최소화)의 조합으로 78장 카드 60fps는 구형 디바이스에서도 충분히 달성 가능.

### Recommended Actions

1. `/makeplan`으로 구현 계획 수립 → MVP 범위 확정 (리플 셔플 1종 + 기본 덱 + 1장/3장 스프레드)
2. Flame은 Phase 2(워시 셔플)에서 도입, Phase 1은 순수 Flutter로 시작
3. 오프라인-퍼스트 필드(syncStatus, version)를 Phase 1 DB 스키마에 미리 포함
4. 센서 엔트로피는 Phase 1에서 기본 구현, Phase 2에서 고도화 (min-entropy 검증, 편향 정규화)

---

## References

개별 보고서의 References 섹션 참조:
- [003_Agent_shuffle_engine.md](./003_Agent_shuffle_engine.md) — Flame/Forge2D 공식 문서, 카드 게임 오픈소스, 성능 벤치마크
- [004_Agent_sensor_rng.md](./004_Agent_sensor_rng.md) — sensors_plus, PointyCastle, 햅틱 API 문서
- [005_Agent_data_offline.md](./005_Agent_data_offline.md) — Drift/Hive/Isar 비교, freezed, 이미지 관리
- [006_Agent_architecture.md](./006_Agent_architecture.md) — Clean Architecture 예시, Riverpod/BLoC, 테스트 프레임워크
