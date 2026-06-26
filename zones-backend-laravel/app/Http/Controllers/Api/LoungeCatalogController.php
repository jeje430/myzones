<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\BuildsPublishedLoungeQuery;
use App\Http\Controllers\Controller;
use App\Http\Resources\LoungeCatalogResource;
use App\Http\Resources\ReviewResource;
use App\Models\Review;
use App\Models\Station;
use App\Support\GeoDistance;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class LoungeCatalogController extends Controller
{
    use BuildsPublishedLoungeQuery;

    public function index(Request $request): JsonResponse
    {
        $query = $this->applyLoungeCatalogFilters($this->publishedLoungesQuery(), $request);

        if ($request->boolean('has_coordinates')) {
            $query->whereNotNull('latitude')->whereNotNull('longitude');
        }

        $stations = $query->orderBy('name')->get();

        if ($request->boolean('is_open')) {
            $stations = $this->filterOpenNow($stations);
        }

        if ($request->filled('latitude') && $request->filled('longitude')) {
            $stations = $this->attachDistanceAndSort(
                $stations,
                (float) $request->float('latitude'),
                (float) $request->float('longitude'),
                $request->filled('radius_km') ? (float) $request->float('radius_km') : null,
            );
        }

        return response()->json(
            LoungeCatalogResource::collection($stations)->resolve()
        );
    }

    public function nearby(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'latitude' => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
            'radius_km' => 'nullable|numeric|min:1|max:500',
            'service' => 'nullable|string|max:40',
            'city' => 'nullable|string|max:120',
            'q' => 'nullable|string|max:255',
        ]);

        $originLat = (float) $validated['latitude'];
        $originLng = (float) $validated['longitude'];
        $radiusKm = (float) ($validated['radius_km'] ?? 100);

        $query = $this->applyLoungeCatalogFilters($this->publishedLoungesQuery(), $request)
            ->whereNotNull('latitude')
            ->whereNotNull('longitude');

        $stations = $query->get();

        $stations = $this->attachDistanceAndSort($stations, $originLat, $originLng, $radiusKm);

        if ($request->boolean('is_open')) {
            $stations = $this->filterOpenNow($stations);
        }

        return response()->json(
            LoungeCatalogResource::collection($stations)->resolve()
        );
    }

    public function show(Station $station): JsonResponse
    {
        $station->loadMissing('manager');
        abort_unless($station->isCustomerVisible(), 404, 'Hall unavailable');

        $station->load([
            'packages' => fn ($q) => $q->where('is_active', true),
            'devices',
            'reviews' => fn ($q) => $q->latest(),
            'comments' => fn ($q) => $q
                ->whereNull('parent_id')
                ->with(['user', 'replies' => fn ($r) => $r->with('user')->oldest()])
                ->latest(),
        ]);

        return response()->json(
            (new LoungeCatalogResource($station))->resolve()
        );
    }

    public function storeReview(Request $request, Station $station): JsonResponse
    {
        $station->loadMissing('manager');
        abort_unless($station->isCustomerVisible(), 404, 'Hall unavailable');

        $user = $request->user();
        abort_unless($user !== null, 401);
        abort_unless($user->hasRole('customer'), 403);

        $validated = $request->validate([
            'category' => 'required|in:general',
            'stars' => 'required|integer|min:1|max:5',
        ]);

        $review = Review::updateOrCreate(
            [
                'station_id' => $station->id,
                'user_id' => $user->id,
                'category' => 'general',
            ],
            [
                'stars' => $validated['stars'],
            ],
        );

        $generalReviews = $station->reviews()->where('category', 'general')->get();
        $station->update([
            'average_rating' => round($generalReviews->avg('stars'), 2),
            'reviews_count' => $generalReviews->count(),
        ]);

        return response()->json([
            'message' => 'تم إرسال التقييم بنجاح',
            'review' => (new ReviewResource($review))->resolve(),
        ], 201);
    }

    /**
     * @param  \Illuminate\Support\Collection<int, Station>  $stations
     * @return \Illuminate\Support\Collection<int, Station>
     */
    private function attachDistanceAndSort(
        $stations,
        float $originLat,
        float $originLng,
        ?float $radiusKm,
    ) {
        return $stations
            ->map(function (Station $station) use ($originLat, $originLng) {
                $km = GeoDistance::haversineKm(
                    $originLat,
                    $originLng,
                    (float) $station->latitude,
                    (float) $station->longitude,
                );

                $station->setAttribute('distance_km', round($km, 2));
                $station->setAttribute('distance_meters', (int) round($km * 1000));

                return $station;
            })
            ->when(
                $radiusKm !== null,
                fn ($collection) => $collection->filter(
                    fn (Station $station) => (float) $station->distance_km <= $radiusKm
                )
            )
            ->sortBy('distance_km')
            ->values();
    }
}
