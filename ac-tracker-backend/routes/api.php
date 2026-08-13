<?php

use App\Http\Controllers\Api\ReminderController;
use App\Http\Controllers\Api\LocationController;
use App\Http\Middleware\VerifyApiKey;
use Illuminate\Support\Facades\Route;

Route::middleware(VerifyApiKey::class)->group(function () {
    Route::apiResource('reminders', ReminderController::class);
    Route::post('reminders/{reminder}/follow-up', [ReminderController::class, 'followUp']);

    Route::post('location-logs', [LocationController::class, 'store']);
    Route::get('location-logs/summary', [LocationController::class, 'daySummary']);
});
