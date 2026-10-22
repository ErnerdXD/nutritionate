# Nutritionate

<p align="center">
  <img src="assets/icon/nutritionate_icon.png" alt="Nutritionate app icon" width="180" />
</p>

<p align="center"><strong>Nutritionate — understand what you eat, one scan at a time.</strong></p>

Nutritionate is a Flutter mobile app that helps people understand packaged-food nutrition quickly and safely. Users can sign in with Google, scan a barcode, photograph a nutrition panel, save product history, and review personal nutrition preferences in one place.

When a barcode is not found, users who enable the optional Nutrition Assistant can submit up to three product photos for AI-assisted research. The assistant can help read nutrition panels, translate visible non-English packaging into English, compare packaging details, and prepare a draft for the user to review. AI features use BYOK (Bring Your Own Key): the user supplies their own Gemini API key, which is stored locally on the device and is not saved in the app database.

## Features

- Google sign-up and login with separate user profiles
- Portrait-only mobile interface
- Barcode scanning with local nutrition-label capture
- Optional three-photo AI product research for unknown products
- English translation support for non-English labels, including Chinese
- Nutrition Assistant for short, food-related questions
- Per-user scan history and product storage
- Age, weight, height, dietary preferences, metric units, and safety acknowledgement
- Saved light/dark appearance preference
- Firebase-backed profiles and a protected Node.js backend

## Technology

- Flutter and Dart
- Firebase Authentication and Cloud Firestore
- Google ML Kit text recognition
- Mobile Scanner and Image Picker
- Node.js, Express, Zod, and Firebase Admin SDK
- Google Gemini through the protected backend
- Render deployment configuration in `render.yaml`

## Project layout

```text
lib/       Flutter application code
backend/   Express API for Gemini-backed features
test/      Flutter tests
assets/    Application assets and icon
render.yaml Render web-service configuration
```

## Run the Flutter app locally

Install Flutter and configure Firebase for the Android application first. Then run:

```powershell
flutter pub get
flutter run
```

The app expects the backend URL from `COACH_API_URL`. For local development, use the default URL for your device type or pass one explicitly:

```powershell
flutter run --dart-define=COACH_API_URL=http://127.0.0.1:8787
```

For a physical Android phone, use a reachable HTTPS or LAN backend URL. Do not commit API keys, service-account JSON, or `.env` files.

## Run the backend locally

```powershell
cd backend
npm ci
$env:GEMINI_API_KEY = 'your-server-key'
$env:ALLOW_INSECURE_LOCAL = 'true'
$env:NODE_ENV = 'development'
npm start
```

`ALLOW_INSECURE_LOCAL` is only for local development. Production deployments must use Firebase token verification, HTTPS, `FIREBASE_PROJECT_ID`, and `FIREBASE_SERVICE_ACCOUNT_JSON` in the hosting provider's secret manager. See [backend/README.md](backend/README.md) for complete deployment requirements.

## Test

```powershell
flutter analyze
flutter test
cd backend
npm test
```

## Privacy and safety

Nutritionate provides general nutrition information, not medical advice. Users should verify AI-generated drafts against the physical package label. Never commit Gemini keys or Firebase service-account credentials to this repository.

## Future scope

Planned improvements include broader product coverage, more language support, meal tracking, stronger nutrition personalization, improved offline behavior, and public release through the Google Play Store.
