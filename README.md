# LangUp Mobile

Flutter-застосунок, що замінює веб-кабінет LangUp (`langup_backend/frontend`).
Споживає той самий API під `/api`. Стратегія й контракти: див.
`langup_backend/docs/MOBILE_STRATEGY.md`.

## Статус — Фаза 0 (каркас під логін)

- Dio-клієнт з **rotating-refresh single-flight** інтерсептором (`lib/core/api_client.dart`)
- Токени в **flutter_secure_storage** (`lib/core/token_store.dart`)
- Riverpod + go_router з редіректами за станом сесії
- Екрани: splash → login/register (+ forgot password) → мовний гейт → home (профіль з `/auth/me`)
- Google Sign-In — кнопка є, але вимкнена: потребує Android/iOS OAuth-конфіг (наступний крок)

## Запуск (dev)

1. Підняти бекенд локально (репо `langup_backend`):
   ```bash
   docker compose up -d
   ```
2. Запустити застосунок:
   ```bash
   flutter run
   ```

### Base URL за замовчуванням
- Android-емулятор → `http://10.0.2.2:8000/api`
- Web/desktop → `http://localhost:8000/api`
- Фізичний телефон (той самий Wi-Fi) — вкажи IP ПК:
  ```bash
  flutter run --dart-define=API_BASE_URL=http://192.168.x.x:8000/api
  ```
- Прод:
  ```bash
  flutter run --dart-define=API_BASE_URL=https://langup.piatek-magazyn.com/api
  ```

## Структура

```
lib/
  core/       config, token_store, api_client, providers, router, languages, models/
  features/
    auth/     splash, login, language gate, repository, controller
    home/     placeholder-профіль (Phase 0)
openapi.json  знімок схеми бекенду — джерело правди для майбутньої кодогенерації
```

## Нотатки / TODO

- `android:usesCleartextTraffic="true"` увімкнено для dev (HTTP на 10.0.2.2). Для
  релізу прод API — HTTPS; варто обмежити cleartext лише debug-конфігом.
- Google Sign-In: додати `google-services.json` (Android, з SHA-1) та iOS OAuth-клієнт.
- Наступні фази: Vocabulary, Practice (5 типів вправ), Review (SM-2), Dashboard, Profile+Payments.
