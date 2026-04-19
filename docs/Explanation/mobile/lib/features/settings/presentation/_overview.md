---
id: "mobile-lib-features-settings-presentation-_overview"
type: explanation
target: "mobile/lib/features/settings/presentation/"
layer: "folder"
version: 1
created: 2026-04-19
updated: 2026-04-19
last_explained_commit: "0336e4c341209b356a3138d22619cde2b7c40eef"
functions: []
---

# settings/presentation/ — 해설

## 개요
설정 피처의 UI 계층이다. Riverpod provider 3개와 화면 2개(카드 크기·앱 설정)로 구성된다.

## 역할 (Role)
설정 상태의 구독(providers)과 표시(pages)를 담당. `userSettingsProvider`가 앱 전체 설정의 반응형 진입점이 된다.

## 구조 (Structure)

```
presentation/
├── providers/   — Riverpod provider 3개
└── pages/       — 화면 2개
```

| 하위 폴더 | 파일 수 | 역할 |
|-----------|---------|------|
| `providers/` | 1 | Repository·스트림·종횡비 provider |
| `pages/` | 2 | 카드 크기 설정, 앱 설정 플레이스홀더 |

## 동작 흐름 (Flow)
1. `userSettingsRepositoryProvider` (keepAlive) — DB 연결 유지
2. `userSettingsProvider` — 설정 스트림 구독, 전체 앱에서 `ref.watch`
3. 변경: `ref.read(userSettingsRepositoryProvider).updateXxx()` 직접 호출
4. 화면 진입: 홈 탭 `카드 크기` → `/settings/card-size`, 프로필 탭 → `/settings`

## 의존성 (Dependencies)

| 대상 | 종류 | 역할 |
|------|------|------|
| `domain/` | 내부 | 엔티티·인터페이스 |
| `data/` | 내부 | Repository 구현체 |
| `core/widgets/mystical_scaffold` | 내부(core) | 화면 래퍼 |

## 주의사항 (Caveats)
- `cardAspectRatioProvider`는 설정 로드 전 기본값(`0.583`)을 반환하므로 첫 프레임 깜박임 가능성 있음.

## 하위 구성 (Contents)
| 구분 | 대상 | 해설 문서 | 한 줄 요약 |
|------|------|----------|-----------|
| 폴더 | `providers/` | [overview](providers/_overview.md) | 설정 Repository·스트림·종횡비 provider |
| 폴더 | `pages/` | [overview](pages/_overview.md) | 카드 크기·앱 설정 두 화면 |

## Changelog
### v1 (2026-04-19) — 최초 작성
- 최초 해설 문서 생성.
