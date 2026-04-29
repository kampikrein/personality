# personality 프로젝트

성격 포탈 + 타로 모바일 — 자기 이해, 타인 수용, 자유 추구.

## 모노레포 구조
- `server/` — Rails 8+ 백엔드 (PostgreSQL, RSpec, Hotwire/Turbo, Tailwind CSS)
- `mobile/` — Flutter 모바일 앱 (타로 + 성격 서비스, 구조만 세팅됨)
- `apps/workers/` — Cloudflare Workers 백엔드 (Hono, D1, R2, KV — TypeScript, Phase 1 Cycle 1부터)
- `shared/` — API 계약 (OpenAPI 스키마, placeholder)
- `docs/` — 공유 문서 (산출물 중앙화)

## Flutter 개발 워크플로우

### 전제 조건
- **에뮬레이터**: 사용자가 Android Studio / AVD Manager에서 별도 실행. Claude Code는 ADB로 접근.
  - 디바이스 확인: `$ANDROID_HOME/platform-tools/adb devices`
  - 연결 디바이스가 없으면 사용자에게 에뮬레이터 실행 요청. 직접 `emulator` 명령 실행 금지.
- **환경 변수**: `ANDROID_HOME=/Users/kampikrein/Library/Android/sdk`
- **앱 패키지명**: `com.personality.personality_mobile`

### 빌드 정책
코드 수정 후 빌드 성공 여부를 반드시 확인한다.

```bash
cd /Users/kampikrein/A/personality/mobile
flutter build apk --debug   # 빌드 성공 확인
```

빌드 실패 시 오류를 해결하고 재빌드. 빌드 성공 확인 없이 완료 보고 금지.

### Hot Reload 표준
- **표준**: 사용자가 VS Code에서 F5로 `flutter run` 실행 → 저장 시 Dart-Code 확장이 자동 hot reload.
- **대안**: 터미널에서 `flutter run` 직접 실행 → 수동 `r` 키로 reload.
- Claude Code는 flutter run 프로세스를 직접 관리하지 않는다 (세션 종속성 방지).

### 스크린샷 검증
UI 변경 시 ADB 스크린샷으로 결과를 시각적으로 확인한다.

```bash
# 스크린샷 캡처 및 Pull
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SAVE_PATH="/Users/kampikrein/A/personality/mobile/tmp/screenshots/screenshot_${TIMESTAMP}.png"
mkdir -p "$(dirname $SAVE_PATH)"
$ANDROID_HOME/platform-tools/adb exec-out screencap -p > "$SAVE_PATH"
# 이후 Read tool로 이미지 확인
```

스크린샷은 `mobile/tmp/screenshots/` 에 저장 (`.gitignore` 처리됨).

### 로그 확인

```bash
# Flutter 로그만 필터링
$ANDROID_HOME/platform-tools/adb logcat -s flutter

# 앱 전체 로그 (패키지 필터)
$ANDROID_HOME/platform-tools/adb logcat | grep -i "personality_mobile"

# 최근 로그만 (이전 로그 무시)
$ANDROID_HOME/platform-tools/adb logcat -T 1 -s flutter
```

### 빠른 참조

| 작업 | 명령 |
|------|------|
| 디바이스 확인 | `adb devices` |
| 앱 실행 | `cd mobile && flutter run` |
| 스크린샷 | `/flutter-dev screenshot` 스킬 사용 |
| 로그 | `adb logcat -s flutter` |
| Release 빌드 설치 | `flutter build apk && adb install build/app/outputs/flutter-apk/app-release.apk` |

# 위임 판단

```
사용자 요청 수신
  │
  ├─ 전문 도메인 지식 불필요?
  │   → 직접 처리
  │     (파일 읽기, 상태 확인, 구조 분석, 질문 답변,
  │      단순 버그 수정, 설정 변경, 리팩터링, docs 정리)
  │
  ├─ 단일 도메인 전문성만 필요?
  │   → 에이전트 1개 위임 (프로토콜 로딩 불필요)
  │   → 프롬프트에 작업 목표·참조 경로·산출물 위치·완료 기준 포함
  │   → 에이전트 산출물 프로토콜 적용 (스켈레톤 즉시 생성 → 점진적 업데이트)
  │
  └─ 오케스트레이션 트리거 해당? ─── 아래 참조 ───
      → `.claude/protocols/orchestration.md` Read 후 진행
```

# 전문 에이전트 (7개)

| 에이전트 | 전문 영역 | 위임 대상 |
|---------|----------|----------|
| `psychology-expert` | 성격심리학, 심리측정학, 학술 검증, 윤리 | 학술 근거, 바넘 효과, 콘텐츠 검증, 타로 해석 윤리 |
| `mbti-expert` | MBTI 문화, 서비스 설계, 문항 개발, 저작권 | 유형 콘텐츠, 문항, MZ세대 맥락 |
| `enneagram-expert` | 9유형, 날개, 본능, 동기 탐색, 성장 방향 | 동기 콘텐츠, 복합 프로필, 성장 가이드 |
| `coding-expert` | Rails 백엔드, TDD, 서비스 패턴, 보안 | Rails 모델/서비스/컨트롤러, API, 테스트 |
| `flutter-expert` | Flutter/Dart, 물리엔진, 센서, 오프라인-퍼스트 | 모바일 앱 구현, 셔플 엔진, 카드 애니메이션 |
| `tarot-expert` | 타로 도메인, 스프레드 설계, 해석 내러티브 | 카드/덱 콘텐츠, 셔플 의식, 커스텀 덱 검증 |
| `uiux-expert` | 감정 흐름, 제의적 UX, WCAG 접근성 | 웹 뷰 구현, UX 설계, Flutter UX 평가 |

# 오케스트레이션 트리거

아래 중 **하나라도 해당**하면 `.claude/protocols/orchestration.md`를 Read한 뒤 진행한다.

| 트리거 | 판단 근거 | 예시 |
|--------|----------|------|
| **다중 에이전트 조합** | 2개+ 전문 영역이 교차 | "문항 만들고 학술 검증", "콘텐츠 설계 + 구현" |
| **평가루프 필요** | 생성물의 품질 검증이 작업에 포함 | "바넘 효과 점검 포함", "학술 근거 검증하면서" |
| **순차 파이프라인** | 여러 단계를 순서대로 연결 | "DB → 서비스 → 뷰" |
| **병렬 실행** | 독립적 작업 2+ 동시 실행 | "5개 관점 분석", "멀티 모듈 동시 리뷰" |
| **확신 없음** | 위 해당 여부가 불명확 | 부실한 오케스트레이션 비용 > 로딩 비용(~2,500토큰) |

해당하지 않는 경우:
- 직접 처리 (파일 읽기, 설정, 단순 수정)
- 단일 에이전트 위임 (한 에이전트에게 작업 하나)

# Docs 산출물 관리

모든 산출물은 `docs/`에 중앙화. 유일한 진실의 원천(source of truth).

```
docs/{NN_카테고리}/{NNN_Type_제목}.md
```

**Type**: `Scope` | `Research` | `Agent` | `Synthesis` | `Plan` | `Memo` | `Reference` | `Session`

**agent-memory/**: 에이전트의 교차 세션 기억 전용 (10~30줄 압축). docs/ 본문을 복제하지 않고 경로만 참조.

# Red Lines

1. **도메인 콘텐츠는 전문 에이전트에 위임**: 성격 유형 문항/설명, 학술 주장은 직접 생성하지 않음
2. **평가루프 3회 초과 금지**
3. **사용자 확인 없이 파괴적 작업 금지**
4. **저작권 침해 콘텐츠 생성 금지**: 공식 MBTI/애니어그램 검사 문항·브랜드 표현 미사용
