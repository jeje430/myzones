<?php

namespace App\Support;

class GeoDistance
{
    private const EARTH_RADIUS_KM = 6371.0;

    public static function haversineKm(
        float $latFrom,
        float $lngFrom,
        float $latTo,
        float $lngTo,
    ): float {
        $latFromRad = deg2rad($latFrom);
        $latToRad = deg2rad($latTo);
        $deltaLat = deg2rad($latTo - $latFrom);
        $deltaLng = deg2rad($lngTo - $lngFrom);

        $a = sin($deltaLat / 2) ** 2
            + cos($latFromRad) * cos($latToRad) * sin($deltaLng / 2) ** 2;

        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));

        return self::EARTH_RADIUS_KM * $c;
    }
}
