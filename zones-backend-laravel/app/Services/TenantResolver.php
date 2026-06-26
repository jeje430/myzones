<?php

namespace App\Services;

use App\Models\Station;
use App\Models\User;

class TenantResolver
{
    public function resolveStationId(User $user): ?int
    {
        if ($user->station_id) {
            return (int) $user->station_id;
        }

        if ($user->hasRole('manager')) {
            $station = $user->relationLoaded('managedStation')
                ? $user->managedStation
                : Station::where('manager_id', $user->id)->first();

            return $station?->id;
        }

        return null;
    }

    public function resolveStation(User $user): ?Station
    {
        $stationId = $this->resolveStationId($user);

        if (! $stationId) {
            return null;
        }

        if ($user->relationLoaded('station') && $user->station?->id === $stationId) {
            return $user->station;
        }

        if ($user->relationLoaded('managedStation') && $user->managedStation?->id === $stationId) {
            return $user->managedStation;
        }

        return Station::find($stationId);
    }
}
