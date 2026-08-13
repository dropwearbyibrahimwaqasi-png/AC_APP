<?php

// Add these lines into your existing routes/api.php

use App\Http\Controllers\Api\ReminderController;
use App\Http\Controllers\Api\LocationController;
use App\Http\Middleware\VerifyApiKey;

Route::middleware(VerifyApiKey::class)->group(function () {
    Route::apiResource('reminders', ReminderController::class);
    Route::post('reminders/{reminder}/follow-up', [ReminderController::class, 'followUp']);

    Route::post('location-logs', [LocationController::class, 'store']);
    Route::get('location-logs/summary', [LocationController::class, 'daySummary']);
});

// Also add this one line to the `return [...]` array in config/services.php:
//     'api_key' => env('API_SECRET_KEY'),
//
// Then add a long random value to your .env (and to Railway's environment
// variables when you deploy):
//     API_SECRET_KEY=paste-a-long-random-string-here
//
// Use the exact same value as the `apiKey` constant in mobile/lib/config.dart.
