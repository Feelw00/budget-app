# budget_app — 가계부 Flutter 앱

[Feelw00/budget](https://github.com/Feelw00/budget) 웹앱의 REST API를 사용하는 **Flutter 클라이언트** (웹 타겟, 모바일 확장 가능). 웹과 **같은 데이터(SQLite)를 공유**한다.

## 기능
로그인 · 대시보드(남은 비용/기간 요약/월별 차트) · 입력(+프리셋 퀵필) · 상세(주/월/연) · 고정비·급여 · 프리셋 · 비밀번호 변경

## 실행
```bash
flutter pub get

# 로컬 백엔드로 개발
flutter run -d chrome --dart-define=API_BASE=http://localhost:3000

# 운영 API (기본값: https://budget.feelw00.com)
flutter run -d chrome
```

## 빌드 (웹)
```bash
flutter build web --release --dart-define=API_BASE=https://budget.feelw00.com
# 산출물: build/web  (정적 호스팅에 배포)
```

## 구조
- `lib/api.dart` — API 클라이언트(Bearer 토큰), `kApiBase`는 `--dart-define=API_BASE`로 재정의
- `lib/auth.dart` — 로그인 상태 + 토큰 영속(shared_preferences)
- `lib/screens/` — login / home(네비) / dashboard / input / detail / presets / fixed / account
- `lib/format.dart` — 원화·색상 헬퍼

인증은 서버가 발급하는 Bearer 토큰(30일)을 사용하며, 서버는 토큰을 SHA-256 해시로만 저장한다.
