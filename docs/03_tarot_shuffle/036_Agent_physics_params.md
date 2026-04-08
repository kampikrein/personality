---
id: "036"
title: "조작감의 물리 파라미터 — forge2d 튜닝 조사"
category: agent
status: archived
created: 2026-03-16
summary: >
  forge2d(Box2D) 타로 카드 78장 물리 시뮬레이션 기준으로 조작감을 결정하는
  핵심 5개 파라미터(friction, restitution, linearDamping, angularDamping, density)의
  카드 적합 권장 수치, applyLinearImpulse vs applyForce 비교, 78장 body 성능
  트레이드오프, 파라미터 영향력 순위를 정리. 고정 타임스텝(1/45s) 적용과
  sleeping body 활용이 성능 확보의 핵심임을 확인.
keywords: [agent-report, forge2d, physics, friction, restitution, damping, card-game, box2d]
modules: []
---

# 조작감의 물리 파라미터 — forge2d 튜닝 조사

## Progress
### Completed
- [x] friction/restitution 카드 권장 값 조사
- [x] linearDamping/angularDamping 조사
- [x] density/질량감 조사
- [x] applyLinearImpulse vs applyForce 비교
- [x] 78장 성능 트레이드오프 조사
- [x] 파라미터 순위 도출
### Remaining
- (없음)
### Current Status
조사 완료.

---

## Summary

타로 카드 78장 물리 시뮬레이션에서 **조작감을 결정하는 파라미터 영향력 순위**:

1. **linearDamping** — 밀었을 때 카드가 멈추는 "무게감/마찰감"의 가장 직접적 결정자
2. **friction** — 카드끼리 / 카드-바닥 접촉 슬라이드 리얼리티
3. **applyLinearImpulse 적용점** — 중심 vs 오프셋이 회전감을 좌우
4. **angularDamping** — 회전이 얼마나 빨리 안정되는가
5. **restitution** — 충돌 후 튕김 정도 (카드는 매우 낮게)
6. **density** — 질량이 임펄스 반응성 스케일에 영향

78장 전체 동시 물리 처리는 Box2D/forge2d의 **sleeping body 자동 최적화** 덕분에
현실적으로 처리 가능. 정지한 카드는 CPU 오버헤드가 극소화된다.
**고정 타임스텝(1/45s)** 적용이 플랫폼별 fps 차이로 인한 물리 불일치를 방지하는 필수 조건.

---

## Details

### 1. friction (마찰계수)

**범위**: 0.0 ~ 1.0+ (음수 불가)
- 0.0: 완전 무마찰 (아이스링크 바닥)
- 0.3: 중간 (일반 테이블 위 카드)
- 0.5: 적당한 저항 (펠트 천 위)
- 1.0: 강한 마찰

**Box2D 결합 공식**: `sqrt(frictionA × frictionB)`
→ 한쪽이 0이면 결합값도 0이 됨.

**타로 카드 권장값**:
- 카드-바닥(테이블): `0.4 ~ 0.5`
- 카드-카드 접촉: `0.3 ~ 0.4`
- 주의: friction은 **접촉 중에만** 작동. 공중에서는 영향 없음.

실전 참조값 (forge2d 실제 코드에서 확인):
- `friction: 0.4` (forge2d 이슈 #2750 예시 코드)

---

### 2. restitution (반발계수)

**범위**: 0.0 ~ 1.0
- 0.0: 완전 비탄성 (충돌 후 즉시 멈춤)
- 0.1: 거의 안 튀김 (카드 느낌)
- 0.5: 중간 탄성
- 1.0: 완전 탄성 (에너지 보존)

**Box2D 결합 공식**: `max(restitutionA, restitutionB)`
→ 한쪽이 높으면 튕김이 발생.

**타로 카드 권장값**: `0.05 ~ 0.15`
- 카드는 종이/플라스틱이라 충돌 후 거의 안 튕김
- 너무 낮으면(0.0) 저속 충돌에서 jitter 발생 가능 → 0.05 이상 권장
- 실전 참조값: `restitution: 0.5` (forge2d 이슈 예시 — 카드엔 과함, 0.1로 줄여야 함)

---

### 3. linearDamping (선형 감쇠)

**범위**: 0.0 ~ 무한대 (통상 0.0 ~ 5.0 사용)

Box2D 공식 문서의 경고:
> "I generally do not use linear damping because it makes bodies look like they are floating."
> — 통상 0 ~ 0.1 권장

그러나 카드 게임에서는 이 역할이 다르다:
- **낮은 값(0.0 ~ 0.5)**: 카드가 밀면 오래 미끄러짐 → 아이스 테이블 느낌
- **중간 값(1.0 ~ 2.0)**: 카드가 짧게 미끄러지다 멈춤 → 테이블 위 카드 느낌
- **높은 값(3.0+)**: 카드가 손에서 떼자마자 거의 즉시 멈춤

**타로 카드 권장값**: `1.5 ~ 3.0`
- 셔플 후 카드가 적당히 미끄러지다 자연스럽게 정지
- damping: 2.0이면 "felted table 위 카드" 질감에 근접
- 주의: friction과 달리 **접촉 없이도** 항상 작동함

**대안 — 커스텀 에어 드래그**: linearDamping 대신 매 프레임 `applyForce(-k * v² * v̂)` 적용으로 더 사실적인 감속 곡선 구현 가능. 단 구현 복잡도 증가.

---

### 4. angularDamping (각감쇠)

**범위**: 0.0 ~ 무한대

- 0.0: 회전이 영원히 지속 (우주 공간)
- 0.5: 서서히 회전 감쇠
- 1.0: 비교적 빠르게 안정
- Box2D 권장 통상값: 0.1

**타로 카드 권장값**: `1.0 ~ 2.0`
- 카드를 밀면 회전하다 자연스럽게 정착
- 너무 낮으면(< 0.5) 카드가 계속 빙글빙글 돔 → 비자연스러움
- 너무 높으면(> 5.0) 회전이 아예 안 일어나는 느낌

실전 참조값: `angularDamping: 0.8` (forge2d 이슈 #2750 예시)
→ 카드 특성에 맞게 1.0 ~ 1.5로 상향 권장

---

### 5. density (밀도)

**단위**: kg/m² (2D 물리라 면적당 질량)
**범위**: 0.0 (정적 body) ~ 무한대

- 0.0: static body용 (움직이지 않음)
- 1.0: 기본 동적 body (breakout 공 예시)
- 2000.0: 콘크리트 벽 (실질적으로 움직이지 않는 dynamic body)

**조작감에서의 역할**:
- density가 높을수록 applyLinearImpulse의 효과가 **줄어듦** (F = ma, 질량 크면 가속 작음)
- density가 낮을수록 카드가 가볍게 반응 → 셔플 느낌 경쾌
- density가 높으면 "무거운 카드" 느낌 → linearDamping과 함께 조정 필요

**타로 카드 권장값**: `0.5 ~ 2.0`
- 가벼운 카드(경쾌한 셔플): `0.5 ~ 1.0`
- 묵직한 고급 카드 느낌: `1.5 ~ 2.0`
- 78장 전체 동일한 density로 통일 권장 (Box2D stacking stability 개선)

---

### 6. applyLinearImpulse vs applyForce vs linearVelocity

#### 비교표

| 방식 | 동작 | 질량 영향 | 셔플 적합성 |
|------|------|----------|------------|
| `applyForce(v)` | 매 프레임 누적 가속 | 있음 (F=ma) | 지속 터치 드래그에 적합 |
| `applyLinearImpulse(v)` | 즉시 속도 변화 | 있음 (I=mv) | 손가락을 떼는 순간 플릭에 최적 |
| `body.linearVelocity = v` | 즉시 속도 덮어씀 | 없음 | 드래그 중 직접 위치 제어에 적합 |

#### 셔플 조작별 권장 방식

| 조작 | 권장 방식 | 이유 |
|------|----------|------|
| 카드 드래그(누르고 이동) | `linearVelocity = dragDelta / dt` | 질량 무관하게 손가락을 정확히 따라옴 |
| 카드 플릭(손가락 떼며 밀기) | `applyLinearImpulse(velocity * mass)` | 즉각적 속도 변화, 질량감 반영 |
| 지속 힘(바람 효과 등) | `applyForce(f)` | 부드러운 누적 가속 |

#### 중요: 적용점(application point)이 회전을 결정

- `applyLinearImpulse(v, body.worldCenter)` → 순수 평행이동, 회전 없음
- `applyLinearImpulse(v, offsetPoint)` → 오프셋만큼 회전 토크 발생
- **타로 셔플**: 카드 모서리 부분을 밀면 자연스럽게 회전 → 오프셋 적용 권장

#### 주의사항 (forge2d 버그 #2750)

Android에서 `applyLinearImpulse` 첫 호출이 매우 약하게 작동하는 버그 존재 (BodyDef `active: false` 초기화 시):
- **회피법**: body 생성 직후 첫 프레임에 `applyForce`로 대체하거나, body 활성화 후 1프레임 대기 후 임펄스 적용

---

### 7. 78장 body 성능 트레이드오프

#### Box2D sleeping body 메커니즘

Box2D/forge2d는 정지한 body를 **자동으로 sleep 상태**로 전환:
- Sleep 중인 body는 CPU 연산에서 제외
- 다른 body와 충돌 시 자동 wake
- **78장 중 실제로 움직이는 카드는 소수** → 대부분 sleep 상태 → 실용적으로 처리 가능

#### 추정 성능 분석

| 상황 | 활성 body 수 | 부하 수준 |
|------|-------------|---------|
| 초기 분산(모든 카드 움직임) | 78개 | 높음 (0.5~2초) |
| 카드 정착 후 | 1~5개(조작 중인 것만) | 매우 낮음 |
| 플릭 후 슬라이딩 | 5~15개 | 낮음 |

#### 최적화 전략

1. **sleeping 활성화 유지**: `bodyDef.allowSleep = true` (기본값, 변경하지 말 것)
2. **Shape 단순화**: 카드는 직사각형(PolygonShape box) 사용 — CircleShape보다 약간 무겁지만 충분
3. **고정 타임스텝 필수**: `dt`를 직접 쓰면 플랫폼별 fps 차이로 물리가 달라짐

```dart
// 권장 고정 타임스텝 패턴 (forge2d 이슈 #3162 검증)
static const double tickLimit = 1.0 / 45;
double currentDt = 0;

void update(double dt) {
  currentDt += dt;
  int cycles = currentDt ~/ tickLimit;
  for (int i = 0; i < cycles; i++) {
    physicsWorld.stepDt(tickLimit);
  }
  currentDt -= cycles * tickLimit;
}
```

4. **isBullet 비활성**: 카드는 빠르게 이동하지 않으므로 tunneling 방지 불필요 (성능 절약)
5. **velocity iteration**: 기본값(8) 유지 — 카드 78장에는 충분

#### 바디 한계

구버전 Box2D는 1024 body 한계가 있었으나 현재 forge2d(Box2D 기반)는 이 제한이 없음. 78장은 여유 있음.

---

## Key Findings

### 타로 카드 78장 권장 파라미터 세트

```dart
// FixtureDef (카드 재질)
fixtureDef
  ..density = 1.0        // 표준 질량감
  ..friction = 0.4       // 카드-카드 슬라이드: 중간 마찰
  ..restitution = 0.05;  // 충돌 후 거의 안 튕김

// BodyDef (카드 운동 특성)
bodyDef
  ..linearDamping = 2.0   // 밀었을 때 빠르게 멈춤 (테이블 위 카드)
  ..angularDamping = 1.2  // 회전 서서히 안정
  ..allowSleep = true;    // 성능 필수
```

### 조작감 영향력 순위 (1위가 가장 큼)

| 순위 | 파라미터 | 영향 내용 | 권장 범위 |
|------|---------|----------|---------|
| 1 | **linearDamping** | 밀었을 때 멈추는 속도감, "무게감" | `1.5 ~ 3.0` |
| 2 | **friction** | 카드끼리/바닥 슬라이드 리얼리티 | `0.3 ~ 0.5` |
| 3 | **impulse 적용점** | 오프셋으로 자연스러운 회전 유발 | 중심 ± 카드 크기의 0.2 |
| 4 | **angularDamping** | 회전 안정화 속도 | `1.0 ~ 2.0` |
| 5 | **restitution** | 충돌 후 튕김 정도 | `0.05 ~ 0.1` |
| 6 | **density** | 임펄스 반응 스케일 | `0.5 ~ 2.0` |

---

## Recommendations

1. **드래그 조작**: `body.linearVelocity = panDelta / dt` — 손가락에 정확하게 붙어오는 느낌
2. **플릭 조작**: `body.applyLinearImpulse(flickVelocity * body.mass)` — 손가락 떼는 속도를 velocity 벡터로 변환해서 적용
3. **회전 유발**: 임펄스 적용점을 카드 중심에서 살짝 오프셋 (`getWorldPoint(Vector2(cardHalfWidth * 0.3, 0))`)
4. **성능**: 고정 타임스텝(1/45s) + allowSleep = true 조합으로 78장도 안정적으로 처리 가능
5. **Android 버그 회피**: 첫 impulse 적용 전 body가 완전히 활성화되었는지 확인 (1프레임 대기 또는 applyForce 대체)
6. **테이블 재질 설정**: 바닥 static body에 `friction: 0.6`을 주면 카드-바닥 결합 마찰이 `sqrt(0.4 * 0.6) ≈ 0.49`로 자연스럽게 계산됨

---

## References

- [Box2D Simulation Documentation](https://box2d.org/documentation/md_simulation.html) — friction, restitution, damping 공식 문서
- [Box2D Dynamics Module](https://box2d.org/doc_version_2_4/md__e_1_2github_2box2d__24_2docs_2dynamics.html) — 파라미터 상세
- [iforce2d Box2D Tutorial: Forces & Impulses](https://www.iforce2d.net/b2dtut/forces) — applyForce vs applyLinearImpulse 비교
- [Kodeco: Breakout Game with Flame & Forge2D](https://www.kodeco.com/35491219-create-a-breakout-game-in-flutter-with-flame-and-forge2d-part-1/page/3) — 실전 파라미터 값
- [forge2d GitHub Issue #2750](https://github.com/flame-engine/flame/issues/2750) — applyLinearImpulse Android 버그
- [forge2d GitHub Issue #3162](https://github.com/flame-engine/flame/issues/3162) — 고정 타임스텝 패턴
- [Yayo Code: Forces, Impulses & Linear Velocity](https://yayocode.com/courses/learn_flame_and_forge2d/forces_impulses_linear_velocity/) — 3가지 방식 비교
- [Flame/Forge2D Official Docs](https://docs.flame-engine.org/latest/bridge_packages/flame_forge2d/forge2d.html)
- [Air Friction in Box2D (Imran's Blog)](https://imranedu.wordpress.com/2015/01/07/how-to-simulate-realistic-air-friction-in-box2d-starling-version/) — 커스텀 에어 드래그 공식
- [Toxigon: Box2D Physics Parameter Tuning](https://toxigon.com/creating-physics-based-games-with-box2d) — 성능 최적화

## Communication Log
| # | 방향 | 상대 | 내용 요약 | 시점(단계) |
|---|------|------|----------|-----------|
| 1 | 수신 | orchestrator | 타로 카드 78장 물리 파라미터 조사 위임 | 시작 |
| 2 | 반환 | orchestrator | 5개 파라미터 + 임펄스 비교 + 성능 분석 완료 | 완료 |

---

## Session Log (auto-appended)

| # | Type | Duration | Tokens |
|---|------|----------|--------|
| 1 | user-ai-exchange | 0s | 0 |
| 2 | user-ai-exchange | 19s | 76045 |
| 3 | user-ai-exchange | 11s | 40778 |
| 4 | user-ai-exchange | 10s | 42195 |
| 5 | user-ai-exchange | 9s | 44183 |
| 6 | user-ai-exchange | 14s | 46529 |
| 7 | user-ai-exchange | 5s | 48356 |
| 8 | user-ai-exchange | 9s | 50568 |
| 9 | user-ai-exchange | 13s | 105037 |
| 10 | user-ai-exchange | 12s | 54453 |
| 11 | user-ai-exchange | 11s | 55874 |
| 12 | user-ai-exchange | 12s | 57359 |
| 13 | user-ai-exchange | 14s | 58996 |
| 14 | user-ai-exchange | 13s | 60582 |
| 15 | user-ai-exchange | 8s | 61831 |
| 16 | user-ai-exchange | 11s | 63033 |
| 17 | user-ai-exchange | 29s | 202688 |
| 18 | user-ai-exchange | 11s | 140060 |
| 19 | user-ai-exchange | 11s | 71985 |
| 20 | user-ai-exchange | 9s | 147944 |
| 21 | user-ai-exchange | 14s | 76148 |
| 22 | user-ai-exchange | 19s | 0 |
| 23 | user-ai-exchange | 10s | 41780 |
| 24 | user-ai-exchange | 13s | 45110 |
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 341150s |
| Total Tokens | 1591534 |
| Input Tokens | 71 |
| Output Tokens | 8834 |
| Cache Read | 1202235 |
| Cache Creation | 380394 |
