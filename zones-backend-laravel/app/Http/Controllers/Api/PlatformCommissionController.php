<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PlatformSetting;
use App\Services\PlatformCommissionService;
use App\Services\PlatformFinanceService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PlatformCommissionController extends Controller
{
    public function __construct(
        private readonly PlatformCommissionService $commission,
        private readonly PlatformFinanceService $platformFinance,
    ) {}

    public function show(Request $request): JsonResponse
    {
        if ($denied = $this->ensureSuperAdmin($request)) {
            return $denied;
        }

        return response()->json([
            'settings' => PlatformSetting::current()->toCommissionPayload(),
        ]);
    }

    public function update(Request $request): JsonResponse
    {
        if ($denied = $this->ensureSuperAdmin($request)) {
            return $denied;
        }

        $validated = $request->validate([
            'platform_commission_rate' => 'required|numeric|min:0|max:'.PlatformCommissionService::MAX_RATE,
        ]);

        $settings = PlatformSetting::current();
        $settings->update([
            'platform_commission_rate' => round((float) $validated['platform_commission_rate'], 2),
        ]);

        return response()->json([
            'message' => 'Platform commission updated successfully',
            'settings' => $settings->fresh()->toCommissionPayload(),
        ]);
    }

    public function summary(Request $request): JsonResponse
    {
        if ($denied = $this->ensureSuperAdmin($request)) {
            return $denied;
        }

        $validated = $request->validate([
            'year' => 'nullable|integer|min:2000|max:2100',
            'month' => 'nullable|integer|min:1|max:12',
        ]);

        $year = (int) ($validated['year'] ?? now()->year);
        $month = (int) ($validated['month'] ?? now()->month);

        return response()->json(
            $this->platformFinance->commissionSummary($year, $month),
        );
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
