<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * A single shared secret is enough here since this is a single-user app
 * (only the AC's phone talks to this API) — no need for full login/token
 * issuance. The Flutter app sends the same key in an X-API-Key header.
 */
class VerifyApiKey
{
    public function handle(Request $request, Closure $next): Response
    {
        $providedKey = $request->header('X-API-Key');
        $expectedKey = config('services.api_key');

        if (!$expectedKey || $providedKey !== $expectedKey) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        return $next($request);
    }
}
