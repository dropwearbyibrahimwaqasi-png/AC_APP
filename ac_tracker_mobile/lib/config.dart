// Single place to set these two values — used by both api_service.dart
// and location_service.dart so they can't drift out of sync.

// Must match API_SECRET_KEY in the backend's .env (see VerifyApiKey middleware).
const String apiKey = 'dev-local-test-key-2026-change-me';

// Your deployed Railway backend URL, ending in /api.
const String apiBaseUrl = 'http://127.0.0.1:8000/api';
