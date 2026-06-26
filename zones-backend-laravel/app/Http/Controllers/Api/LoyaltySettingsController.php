<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PlatformSetting;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class LoyaltySettingsController extends Controller
{
    public function show(): JsonResponse
    {
        return response()->json([
            'settings' => PlatformSetting::current()->toLoyaltyPayload(),
        ]);
    }

    public function update(Request $request): JsonResponse
    {
        if ($denied = $this->ensureSuperAdmin($request)) {
            return $denied;
        }

        $validated = $request->validate([
            'points_per_completed_session' => 'required|integer|min:1|max:100000',
            'minimum_points_required' => 'required|integer|min:1|max:1000000',
        ]);

        $settings = PlatformSetting::current();
        $settings->update([
            'loyalty_points_per_session' => $validated['points_per_completed_session'],
            'loyalty_minimum_points_required' => $validated['minimum_points_required'],
        ]);

        return response()->json([
            'message' => 'Loyalty settings updated successfully',
            'settings' => $settings->fresh()->toLoyaltyPayload(),
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
