# Explanation Index
> Last updated: 2026-04-19

| Target | Layer | Version | Updated | Summary |
|--------|-------|---------|---------|---------|
| [mobile/lib/features/](mobile/lib/features/_overview.md) | folder | v1 | 2026-04-16 | Flutter 앱 8개 피처 수직 분리 최상위 디렉토리 |
| [mobile/lib/features/draw/](mobile/lib/features/draw/_overview.md) | folder | v1 | 2026-04-16 | 타로 뽑기 UX 오케스트레이션 피처 |
| [mobile/lib/features/draw/presentation/](mobile/lib/features/draw/presentation/_overview.md) | folder | v1 | 2026-04-16 | 순수 presentation 피처 — pages + providers |
| [mobile/lib/features/draw/presentation/pages/](mobile/lib/features/draw/presentation/pages/_overview.md) | folder | v1 | 2026-04-16 | 연출(Lv2) + 통합 결과(Lv1~4) 두 화면 |
| [mobile/lib/features/draw/presentation/pages/animated_draw_page.dart](mobile/lib/features/draw/presentation/pages/animated_draw_page.md) | file | v1 | 2026-04-16 | Lv2 연출 뽑기 — 셔플 + 스태거 애니메이션 |
| [mobile/lib/features/draw/presentation/pages/draw_result_page.dart](mobile/lib/features/draw/presentation/pages/draw_result_page.md) | file | v1 | 2026-04-16 | Lv1~Lv4 통합 결과 페이지 |
| [mobile/lib/features/draw/presentation/providers/](mobile/lib/features/draw/presentation/providers/_overview.md) | folder | v1 | 2026-04-16 | executeDraw 셔플 provider (예비 use case) |
| [mobile/lib/features/draw/presentation/providers/draw_providers.dart](mobile/lib/features/draw/presentation/providers/draw_providers.md) | file | v1 | 2026-04-16 | one-shot 셔플 실행 오케스트레이터 provider |
| [mobile/lib/features/home/presentation/pages/home_page.dart](mobile/lib/features/home/presentation/pages/home_page.md) | file | v1 | 2026-04-19 | 뽑기 탭 루트 — 오브 버튼·설정 단일 스크롤 |
| [mobile/lib/features/settings/](mobile/lib/features/settings/_overview.md) | folder | v1 | 2026-04-19 | 사용자 설정 전체를 관리하는 피처 모듈 |
| [mobile/lib/features/settings/data/](mobile/lib/features/settings/data/_overview.md) | folder | v1 | 2026-04-19 | 설정 도메인의 Drift 기반 데이터 레이어 |
| [mobile/lib/features/settings/data/repositories/](mobile/lib/features/settings/data/repositories/_overview.md) | folder | v1 | 2026-04-19 | Drift 기반 설정 Repository 구현체 |
| [mobile/lib/features/settings/data/repositories/user_settings_repository_impl.dart](mobile/lib/features/settings/data/repositories/user_settings_repository_impl.md) | file | v1 | 2026-04-19 | Drift 기반 설정 Repository 구현 + _toDomain 매퍼 |
| [mobile/lib/features/settings/domain/](mobile/lib/features/settings/domain/_overview.md) | folder | v1 | 2026-04-19 | 설정 피처의 순수 도메인 계층 |
| [mobile/lib/features/settings/domain/entities/](mobile/lib/features/settings/domain/entities/_overview.md) | folder | v1 | 2026-04-19 | 설정 도메인 값 객체 2개 |
| [mobile/lib/features/settings/domain/entities/card_size_preset.dart](mobile/lib/features/settings/domain/entities/card_size_preset.md) | file | v1 | 2026-04-19 | 7개 타로 카드 크기 프리셋 열거형 |
| [mobile/lib/features/settings/domain/entities/user_settings.dart](mobile/lib/features/settings/domain/entities/user_settings.md) | file | v1 | 2026-04-19 | 앱 전체 사용자 설정 불변 값 객체 (13개 필드) |
| [mobile/lib/features/settings/domain/repositories/](mobile/lib/features/settings/domain/repositories/_overview.md) | folder | v1 | 2026-04-19 | 설정 읽기·쓰기 추상 계약 폴더 |
| [mobile/lib/features/settings/domain/repositories/user_settings_repository.dart](mobile/lib/features/settings/domain/repositories/user_settings_repository.md) | file | v1 | 2026-04-19 | 설정 읽기·쓰기 추상 인터페이스 12개 메서드 |
| [mobile/lib/features/settings/presentation/](mobile/lib/features/settings/presentation/_overview.md) | folder | v1 | 2026-04-19 | 설정 피처의 Riverpod provider + 화면 계층 |
| [mobile/lib/features/settings/presentation/pages/](mobile/lib/features/settings/presentation/pages/_overview.md) | folder | v1 | 2026-04-19 | 카드 크기·앱 설정 두 화면 |
| [mobile/lib/features/settings/presentation/pages/card_size_settings_page.dart](mobile/lib/features/settings/presentation/pages/card_size_settings_page.md) | file | v1 | 2026-04-19 | 카드 크기 프리셋 선택 + 커스텀 입력 페이지 |
| [mobile/lib/features/settings/presentation/pages/settings_page.dart](mobile/lib/features/settings/presentation/pages/settings_page.md) | file | v1 | 2026-04-19 | 앱 설정 플레이스홀더 페이지 |
| [mobile/lib/features/settings/presentation/providers/](mobile/lib/features/settings/presentation/providers/_overview.md) | folder | v1 | 2026-04-19 | 설정 Riverpod provider 3개 진입점 |
| [mobile/lib/features/settings/presentation/providers/settings_providers.dart](mobile/lib/features/settings/presentation/providers/settings_providers.md) | file | v1 | 2026-04-19 | 설정 Repository·스트림·종횡비 provider 3개 |
