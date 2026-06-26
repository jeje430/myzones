<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PlatformSetting;
use App\Support\BrandingStorage;
use App\Support\MediaUrl;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class BrandingLogoController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        if ($denied = $this->ensureSuperAdmin($request)) {
            return $denied;
        }

        $validated = $request->validate([
            'logo' => 'required|file|mimes:png,jpg,jpeg,svg|max:2048',
        ]);

        $settings = PlatformSetting::current();

        $path = BrandingStorage::storeFromUpload(
            $validated['logo'],
            $settings->platform_logo_path,
        );

        $settings->update(['platform_logo_path' => $path]);

        return response()->json([
            'message' => 'تم تحديث شعار المنصة',
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
