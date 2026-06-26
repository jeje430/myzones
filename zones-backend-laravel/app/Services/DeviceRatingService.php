<?php

namespace App\Services;

use App\Models\Device;
use App\Models\DeviceRating;
use App\Models\Package;
use App\Models\Station;
use App\Models\User;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

class DeviceRatingService
{
    /**
     * Upsert ratings for catalog devices (packages) and recalculate aggregates.
     *
     * @param  list<array{device_id: int|string, rating_value: int, comment?: string|null}>  $ratings
     * @return Collection<int, DeviceRating>
     */
    public function upsertBatch(User $user, Station $station, array $ratings): Collection
    {
        return DB::transaction(function () use ($user, $station, $ratings) {
            $saved = collect();

            foreach ($ratings as $row) {
                $packageId = (int) $row['device_id'];

                $targetPackage = Package::query()
                    ->where('id', $packageId)
                    ->where('station_id', $station->id)
                    ->where('is_active', true)
                    ->firstOrFail();

                $rating = DeviceRating::updateOrCreate(
                    [
                        'user_id' => $user->id,
                        'package_id' => $targetPackage->id,
                    ],
                    [
                        'rating_value' => $row['rating_value'],
                    ],
                );

                $this->recalculatePackageAggregates($targetPackage);
                $saved->push($rating);
            }

            return $saved;
        });
    }

    public function recalculatePackageAggregates(Package $package): void
    {
        $stats = DeviceRating::query()
            ->where('package_id', $package->id)
            ->selectRaw('AVG(rating_value) as avg_rating, COUNT(*) as total')
            ->first();

        $average = round((float) ($stats->avg_rating ?? 0), 2);
        $count = (int) ($stats->total ?? 0);

        $package->update([
            'average_rating' => $average,
            'ratings_count' => $count,
        ]);

        Device::query()
            ->where('package_id', $package->id)
            ->update([
                'average_rating' => $average,
                'ratings_count' => $count,
            ]);
    }
}
