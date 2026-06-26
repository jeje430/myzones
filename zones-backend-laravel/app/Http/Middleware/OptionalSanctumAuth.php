<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Laravel\Sanctum\PersonalAccessToken;
use Symfony\Component\HttpFoundation\Response;

/**
 * Authenticates Sanctum bearer tokens when present, without blocking guests.
 */
class OptionalSanctumAuth
{
    public function handle(Request $request, Closure $next): Response
    {
        if ($request->user() === null && ($token = $request->bearerToken())) {
            $accessToken = PersonalAccessToken::findToken($token);

            if ($accessToken !== null
                && ($accessToken->expires_at === null || $accessToken->expires_at->isFuture())) {
                $request->setUserResolver(static fn () => $accessToken->tokenable);
            }
        }

        return $next($request);
    }
}
