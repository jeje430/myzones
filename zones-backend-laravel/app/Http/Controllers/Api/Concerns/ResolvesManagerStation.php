<?php

namespace App\Http\Controllers\Api\Concerns;

use App\Models\Station;
use App\Models\User;
use Illuminate\Http\JsonResponse;

trait ResolvesManagerStation
{
    protected function resolveManagerStation(User $user): ?Station
    {
        $stationId = $user->resolvedStationId();

        if (! $stationId) {
            return null;
        }

        $station = Station::find($stationId);

        if (! $station || ! $user->hasRole('manager')) {
            return null;
        }

        if ($station->manager_id !== null && (int) $station->manager_id !== (int) $user->id) {
            return null;
        }

        return $station;
    }

    protected function managerStationMissingResponse(): JsonResponse
    {
        return response()->json([
            'message' => 'لا توجد صالة مرتبطة بهذا الحساب',
        ], 404);
    }
}
