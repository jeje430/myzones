<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Str;

class GoogleIdTokenVerifier
{
    /**
     * @return array{google_id: string, email: string, name: string}|null
     */
    public function verify(string $idToken): ?array
    {
        $response = Http::get('https://oauth2.googleapis.com/tokeninfo', [
            'id_token' => $idToken,
        ]);

        if (! $response->successful()) {
            return null;
        }

        $payload = $response->json();

        if (! is_array($payload)) {
            return null;
        }

        $email = $payload['email'] ?? null;
        $googleId = $payload['sub'] ?? null;

        if (! $email || ! $googleId) {
            return null;
        }

        $expectedAudience = config('services.google.client_id');
        if ($expectedAudience && ($payload['aud'] ?? null) !== $expectedAudience) {
            return null;
        }

        if (($payload['email_verified'] ?? 'false') !== 'true' && ($payload['email_verified'] ?? false) !== true) {
            return null;
        }

        $name = $payload['name'] ?? Str::before($email, '@');

        return [
            'google_id' => (string) $googleId,
            'email' => strtolower((string) $email),
            'name' => (string) $name,
        ];
    }
}
