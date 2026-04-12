# personality

성격 포탈 + 타로 모바일 서비스 — 자기 이해, 타인 수용, 자유 추구.

## 구조

```
personality/
├── server/     Rails 백엔드 (API + 웹)
├── mobile/     Flutter 모바일 앱
├── shared/     API 스키마 (공유 계약)
└── docs/       프로젝트 문서
```

## 시작하기

### Server (Rails)

```bash
cd server
bundle install
bin/rails db:prepare
bin/dev
```

### Mobile (Flutter)

```bash
cd mobile
flutter pub get
flutter run
```

#### Android SDK 구동

```bash
# 연결된 기기/에뮬레이터 목록 확인
flutter devices

# 사용 가능한 에뮬레이터 목록 확인
flutter emulators

# 에뮬레이터 실행
flutter emulators --launch <emulator_id>

# Android 기기/에뮬레이터로 실행
flutter run -d android

# 특정 기기 지정 실행
flutter run -d <device_id>

# 환경 점검 (Android SDK 경로 등)
flutter doctor
```

### 전체 (Makefile)

```bash
make setup        # 전체 의존성 설치
make server-start # Rails 개발 서버
make server-test  # RSpec 실행
make mobile-run   # Flutter 실행
```
