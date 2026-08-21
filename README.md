# LangUp Mobile

Flutter-застосунок, що замінює веб-кабінет LangUp (`langup_backend/frontend`).
Споживає той самий API під `/api`. Стратегія й контракти: див.
`langup_backend/docs/MOBILE_STRATEGY.md`.

## Статус — Фази 0–1

- Dio-клієнт з **rotating-refresh single-flight** інтерсептором (`lib/core/api_client.dart`)
- Токени в **flutter_secure_storage** (`lib/core/token_store.dart`)
- Riverpod + go_router з редіректами за станом сесії
- Екрани: splash → login/register (+ forgot password, **Google Sign-In**) → мовний гейт → home
- Home: банер підтвердження email з resend + оновлення профілю
- Google Sign-In реалізовано в коді (`lib/features/auth/google_auth_service.dart`);
  щоб кнопка запрацювала на Android — виконати «Google OAuth setup» нижче

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

## Google OAuth setup (щоб запрацювала кнопка Google на Android)

Потрібен доступ до **Google Cloud Console** проекту, де вже створено веб-OAuth-клієнт
бекенду (`AppConfig.googleServerClientId`). Кроки:

1. APIs & Services → Credentials → **Create OAuth client ID** → **Android**.
2. Package name: **`com.langup.langup_mobile`**
3. SHA-1 (debug-ключ цієї машини):
   **`28:21:D2:75:36:02:E2:7B:F9:48:74:9A:9F:4F:42:B2:29:86:41:00`**
   (для релізу з Play App Signing додати ще SHA-1 з Play Console).
4. Зберегти. `google-services.json` **не обов'язковий** для базового id-token flow —
   застосунок передає `serverClientId` (веб-клієнт) напряму в `google_sign_in`.
5. Перевірити: `flutter run` на емуляторі/телефоні → «Continue with Google».

SHA-1 для іншої машини:
```bash
keytool -list -v -alias androiddebugkey -keystore %USERPROFILE%\.android\debug.keystore -storepass android
```

iOS налаштовується окремо (OAuth-клієнт типу iOS + `Info.plist` URL scheme) — знадобиться на етапі iOS-збірки на macOS.

## Нотатки / TODO

- `android:usesCleartextTraffic="true"` увімкнено для dev (HTTP на 10.0.2.2). Для
  релізу прод API — HTTPS; варто обмежити cleartext лише debug-конфігом.
- Наступні фази: Vocabulary, Practice (5 типів вправ), Review (SM-2), Dashboard, Profile+Payments.
