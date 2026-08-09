# Nutritionate AI backend

The Gemini key is read from `GEMINI_API_KEY` at runtime and is never sent to the Flutter app.

## Local development

Set these values in the shell that starts the server:

```powershell
$env:GEMINI_API_KEY = [Environment]::GetEnvironmentVariable('GEMINI_API_KEY', 'User')
$env:ALLOW_INSECURE_LOCAL = 'true'
$env:NODE_ENV = 'development'
npm start
```

Keep that terminal open, then start Flutter in another terminal. The Android
emulator uses `http://10.0.2.2:8787` by default; desktop uses
`http://127.0.0.1:8787`. For a physical phone, bind the backend to your LAN
interface and provide its URL at build time:

```powershell
$env:HOST = '0.0.0.0'
npm start
flutter run --dart-define=COACH_API_URL=http://YOUR_COMPUTER_LAN_IP:8787
```

`ALLOW_INSECURE_LOCAL` bypasses Firebase user verification only for local development. Never set it in production.

## Production requirements

- Store `GEMINI_API_KEY` in the hosting provider's secret manager.
- Set `NODE_ENV=production`.
- Set `FIREBASE_PROJECT_ID` and `FIREBASE_SERVICE_ACCOUNT_JSON`. The latter is
  the complete service-account JSON stored as a secret environment variable.
- Requests must include the signed-in user's Firebase ID token.
- Use HTTPS only.
- Do not enable `ALLOW_INSECURE_LOCAL`.
- Configure provider-level quotas, billing alerts, logging retention, and a kill switch.
