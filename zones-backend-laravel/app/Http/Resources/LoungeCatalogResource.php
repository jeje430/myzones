<?php

namespace App\Http\Resources;

use App\Models\Package;
use App\Models\Station;
use App\Support\MediaUrl;
use App\Services\BookingStopService;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class LoungeCatalogResource extends JsonResource
{
    /** @var Station */
    public $resource;

    public function toArray(Request $request): array
    {
        $station = $this->resource;
        $stopService = app(BookingStopService::class);
        $activeStop = $stopService->activeForStation($station);

        return [
            'id' => (string) $station->id,
            'name' => $station->name,
            'location' => $this->locationLabel($station),
            'city' => $station->city,
            'address' => $station->address ?? '',
            'description' => $station->description ?? '',
            'phone' => $station->phone,
            'map_link' => $station->map_link,
            'image_url' => MediaUrl::resolve($station->cover_image) ?? '',
            'cover_image' => MediaUrl::resolve($station->cover_image) ?? '',
            'latitude' => $station->latitude !== null ? (float) $station->latitude : null,
            'longitude' => $station->longitude !== null ? (float) $station->longitude : null,
            'opens_at' => $station->opens_at ? substr((string) $station->opens_at, 0, 5) : null,
            'closes_at' => $station->closes_at ? substr((string) $station->closes_at, 0, 5) : null,
            'services' => $this->formatCatalogServices($station->available_services ?? []),
            'average_rating' => (float) $station->average_rating,
            'reviews_count' => (int) $station->reviews_count,
            'is_open' => $this->isOpenNow($station),
            'is_published' => (bool) $station->is_published,
            'distance_km' => $station->distance_km ?? null,
            'distance_meters' => $station->distance_meters ?? null,
            'devices' => $this->deviceRows($station),
            'reviews' => ReviewResource::collection($station->reviews)->resolve(),
            'comments' => $this->commentRows($station),
            'user_hall_rating' => $this->userHallRating($station),
            'booking_stop' => $stopService->publicPayload($activeStop),
            'bookings_blocked' => $activeStop !== null,
        ];
    }

    /**
     * @return list<array<string, mixed>>
     */
    private function commentRows(Station $station): array
    {
        if (! $station->relationLoaded('comments')) {
            return [];
        }

        $topLevel = $station->comments->whereNull('parent_id');

        return StationCommentResource::collection($topLevel)->resolve();
    }

    private function userHallRating(Station $station): ?int
    {
        $userId = request()->user()?->id;
        if (! $userId) {
            return null;
        }

        $review = $station->reviews
            ->where('user_id', $userId)
            ->where('category', 'general')
            ->first();

        return $review ? (int) $review->stars : null;
    }

    /**
     * @param  array<int, string>|null  $keys
     * @return list<array<string, mixed>>
     */
    private function formatCatalogServices(?array $keys): array
    {
        $labels = [
            'ps5' => 'PS5',
            'xbox' => 'XBOX',
            'vr' => 'VR',
            'vip' => 'VIP',
            'simulator' => 'SIMULATOR',
            'racing' => 'RACING',
            'pc' => 'PC',
            'free_wifi' => 'Free WiFi',
            'snacks' => 'سناكس',
            'cafeteria' => 'كافتيريا',
        ];

        return array_values(array_map(
            fn ($key) => [
                'key' => $key,
                'label' => $labels[$key] ?? $key,
                'shortLabel' => $labels[$key] ?? $key,
            ],
            array_filter($keys ?? [], fn ($k) => isset($labels[$k])),
        ));
    }

    private function locationLabel(Station $station): string
    {
        if ($station->address) {
            return $station->address;
        }

        return $station->city ?? '';
    }

    private function isOpenNow(Station $station): bool
    {
        if (! $station->is_active || ! $station->bookings_enabled) {
            return false;
        }

        if ($station->opens_at === null || $station->closes_at === null) {
            return true;
        }

        $now = now()->format('H:i:s');
        $opens = (string) $station->opens_at;
        $closes = (string) $station->closes_at;

        if ($opens <= $closes) {
            return $now >= $opens && $now <= $closes;
        }

        return $now >= $opens || $now <= $closes;
    }

    /**
     * @return list<array<string, mixed>>
     */
    private function deviceRows(Station $station): array
    {
        $userId = request()->user()?->id;

        $userRatings = $userId
            ? \App\Models\DeviceRating::query()
                ->where('user_id', $userId)
                ->whereIn(
                    'package_id',
                    $station->packages->where('is_active', true)->pluck('id'),
                )
                ->pluck('rating_value', 'package_id')
            : collect();

        return $station->packages
            ->where('is_active', true)
            ->map(function (Package $package) use ($station, $userRatings) {
                $availableCount = $station->devices
                    ->where('package_id', $package->id)
                    ->where('operational_status', 'active')
                    ->count();

                return [
                    'id' => (string) $package->id,
                    'package_id' => $package->id,
                    'type' => $package->package_type,
                    'name_ar' => $package->name,
                    'hourly_rate' => (float) $package->hourly_price,
                    'available_count' => $availableCount,
                    'average_rating' => (float) $package->average_rating,
                    'ratings_count' => (int) $package->ratings_count,
                    'user_rating' => $userRatings->has($package->id)
                        ? (int) $userRatings->get($package->id)
                        : null,
                    'specs' => $package->description,
                ];
            })
            ->values()
            ->all();
    }
}
