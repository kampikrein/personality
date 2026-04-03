---
id: "055"
type: scope
title: "RNG 최적화 구현 — Fisher-Yates + Random.secure() 교체"
created: 2026-03-17
complexity: simple
research_needed: false
research_reason: "연구 054 완료됨 — 구현 방법론/대상 파일 모두 명확, 추가 조사 불필요"
auto_run: true
effort_mode: bypass
uncertainty_level: low
intent: >
  연구 054의 핵심 발견(3 Critical + 2 High)을 구현한다.
  현재 복잡한 파이프라인(센서→SHA-256→Fortuna→리플3회)을
  수학적으로 완벽한 단순 구조(Random.secure()→Fisher-Yates)로 교체.
  센서 엔트로피는 제의적 UX로 유지하되 보안 의존을 제거한다.
summary: >
  단일 영역(shuffle 도메인). Fisher-Yates 셔플 전략 신규 + Fortuna/리플 교체,
  센서 결함 수정, 건강 테스트 추가, pointycastle 의존성 제거. ~8개 파일 변경.
keywords: [Fisher-Yates, Random.secure, Fortuna-removal, sensor-fix, health-test, pointycastle]
---

# RNG 최적화 구현 — Fisher-Yates + Random.secure() 교체

## 작업 목표
- 연구 054의 Critical/High 발견 사항 구현
- 수학적으로 증명된 균등 분포(1/n!) 보장
- 아키텍처 단순화: 4-레이어 → 2-레이어
- 성공 기준: Fisher-Yates + Random.secure() 기반 셔플, Fortuna/pointycastle 제거, 빌드 통과

## 접근 방향
연구가 권장한 "가장 단순하고 가장 강력한" 아키텍처 직접 구현:
```
[현재] 센서 → SHA-256 → Fortuna → 리플3회
[목표] Random.secure() → Fisher-Yates + 센서(UX 전용, 선택적 추가 믹싱)
```

## Research 판단
- **판단**: 불필요
- **근거**: 연구 054에서 알고리즘·CSPRNG·엔트로피·검증 4관점 조사 완료. 구현 대상 파일과 변경 방법 모두 확정.
- **파이프라인**: S → P → I(V)

## 설계

### 변경 사항 (우선순위 순)

#### 1. [Critical] Fisher-Yates 셔플 전략 신규 생성
- `riffle_shuffle_strategy.dart` → `fisher_yates_shuffle_strategy.dart`로 교체
- Knuth Fisher-Yates: `for i from n-1 downto 1: swap(deck[i], deck[random(0..i)])`
- 역방향 확률(reversals) 로직 유지
- `ShuffleResult.entropyBits`를 실제 추정치로 업데이트

#### 2. [Critical] Fortuna 제거 + Random.secure() 직접 사용
- `fortuna_random_wrapper.dart` 삭제
- `shuffle_deck_usecase.dart`: `FortunaRandomWrapper(seed)` → `Random.secure()`
- `pubspec.yaml`: `pointycastle: ^3.7.0` 제거

#### 3. [Critical] 센서 seedContribution 수정
- `sensor_data_collector.dart:17`: `accelMagnitude * gyroZ` → `accelMagnitude + gyroZ.abs()`
- gyroZ≈0 시 엔트로피 기여 0 문제 해결

#### 4. [High] 센서 건강 테스트 추가
- `entropy_pool.dart`에 RCT/APT 간이 구현
- `minSamples` 10 → 50 증가

#### 5. [High] ShuffleConfig 정리
- `shuffleCount` 제거 또는 Fisher-Yates에서 무시하도록 처리
- freezed 모델 재생성

#### 6. 프로바이더 업데이트
- `shuffle_providers.dart`: `RiffleShuffleStrategy` → `FisherYatesShuffleStrategy`
- usecase 의존성 단순화

### 변경 대상 파일

| 파일 | 변경 유형 | 설명 |
|------|----------|------|
| `riffle_shuffle_strategy.dart` | **삭제** | Fisher-Yates로 대체 |
| `fisher_yates_shuffle_strategy.dart` | **신규** | Knuth Fisher-Yates 구현 |
| `fortuna_random_wrapper.dart` | **삭제** | Random.secure()로 대체 |
| `shuffle_deck_usecase.dart` | **수정** | Fortuna → Random.secure(), 파이프라인 단순화 |
| `sensor_data_collector.dart` | **수정** | seedContribution 공식 수정 |
| `entropy_pool.dart` | **수정** | 건강 테스트 추가, minSamples 증가 |
| `shuffle_config.dart` | **수정** | shuffleCount 처리 |
| `shuffle_providers.dart` | **수정** | 전략 교체, 의존성 업데이트 |
| `pubspec.yaml` | **수정** | pointycastle 제거 |

자동 재생성: `shuffle_config.freezed.dart`, `shuffle_config.g.dart`, `shuffle_providers.g.dart`, `pubspec.lock`

### 리플 애니메이션 유지
연구 054 권장: "리플 애니메이션은 시각적 제의 경험으로만 유지하는 하이브리드 접근"
→ 프레젠테이션 레이어(`riffle_animation_controller.dart`, `hand_animation_component.dart`)는 변경 없음.
  실제 셔플 로직만 Fisher-Yates로 교체.

## 체크포인트 & 컨텍스트 관리

| 체크포인트 | 산출물 | 컨텍스트 조치 | 판단 기준 |
|-----------|--------|-------------|----------|
| /scope 완료 | 이 문서 | **유지** | scope에서 읽은 파일 = makeplan에서 읽을 파일 (높은 overlap) |
| /makeplan 완료 | Plan 문서 | **유지** | plan에서 읽은 파일 = impl에서 수정할 파일 |
| /implementation 완료 | 커밋 + verify | 완료 | — |
