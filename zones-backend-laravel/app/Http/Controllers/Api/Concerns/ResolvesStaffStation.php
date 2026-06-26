<?php

namespace App\Http\Controllers\Api\Concerns;

use App\Models\Station;
use App\Models\User;

trait ResolvesStaffStation
{
    protected function resolveStaffStation(User $user): ?Station
    {
        $stationId = $user->resolvedStationId();

        if (! $stationId) {
            return null;
        }

        if (! $user->hasAnyRole(['manager', 'reception', 'maintenance'])) {
            return null;
        }

        return Station::find($stationId);
    }
}
