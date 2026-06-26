<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PlatformSetting;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class BrandingSettingsController extends Controller
{
    public function show(): JsonResponse
    {
        return response()->json(
            PlatformSetting::current()->toBrandingPayload()
        );
    }

    public function update(Request $request): JsonResponse
    {
        if ($denied = $this->ensureSuperAdmin($request)) {
            return $denied;
        }

        $validated = $request->validate([
            'platform_name' => 'required|string|min:2|max:120',
        ]);

        $settings = PlatformSetting::current();
        $settings->update([
            'platform_name' => trim($validated['platform_name']),
        ]);

        return response()->json([
            'message' => 'تم تحديث إعدادات العلامة التجارية',
            'branding' => $settings->fresh()->toBrandingPayload(),
        ]);
    }

    private function ensureSuperAdmin(Request $request): ?JsonResponse
    {
        $user = $request->user();

        if (! $user || ! $user->hasRole('super_admin')) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        return null;
    }
}
