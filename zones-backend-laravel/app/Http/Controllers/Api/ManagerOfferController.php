<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ResolvesManagerStation;
use App\Http\Controllers\Controller;
use App\Http\Resources\ManagerOfferResource;
use App\Models\Offer;
use App\Models\Package;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ManagerOfferController extends Controller
{
    use ResolvesManagerStation;

    public function index(Request $request): JsonResponse
    {
        $station = $this->resolveManagerStation($request->user());
        if (! $station) {
            return $this->managerStationMissingResponse();
        }

        $offers = Offer::query()
            ->where('station_id', $station->id)
            ->with(['package', 'station'])
            ->withCount(['bookings'])
            ->orderByDesc('created_at')
            ->get();

        return response()->json([
            'offers' => ManagerOfferResource::collection($offers)->resolve(),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $station = $this->resolveManagerStation($request->user());
        if (! $station) {
            return $this->managerStationMissingResponse();
        }

        $validated = $this->validateOffer($request);
        $package = $this->resolveStationPackage($station->id, (int) $validated['package_id']);

        $prices = $this->calculatePrices($package, (int) $validated['discount_percent']);

        $offer = DB::transaction(function () use ($station, $package, $validated, $prices) {
            $offer = Offer::create([
                'station_id' => $station->id,
                'package_id' => $package->id,
                'title' => $validated['title'],
                'description' => $validated['description'] ?? '',
                'valid_from' => $validated['valid_from'],
                'expires_at' => $validated['expires_at'],
                'original_price' => $prices['original'],
                'discounted_price' => $prices['discounted'],
                'discount_percent' => $prices['discount_percent'],
                'offer_image' => $package->thumbnail ?: $station->cover_image,
                'is_active' => $validated['is_active'] ?? true,
            ]);

            $offer->timeSlots()->create([
                'time_range' => '09:00 - 23:00',
                'is_available' => true,
            ]);

            return $offer;
        });

        $offer->load(['package', 'station'])->loadCount(['bookings']);

        return response()->json([
            'message' => 'تم إضافة العرض',
            'offer' => (new ManagerOfferResource($offer))->resolve(),
        ], 201);
    }

    public function update(Request $request, Offer $offer): JsonResponse
    {
        $station = $this->resolveManagerStation($request->user());
        if (! $station || (int) $offer->station_id !== (int) $station->id) {
            return response()->json(['message' => 'العرض غير موجود'], 404);
        }

        $validated = $this->validateOffer($request, $offer);
        $packageId = (int) ($validated['package_id'] ?? $offer->package_id);
        $package = $this->resolveStationPackage($station->id, $packageId);
        $discountPercent = (int) ($validated['discount_percent'] ?? $offer->discount_percent ?? 0);
        $prices = $this->calculatePrices($package, $discountPercent);

        $offer->update([
            'package_id' => $package->id,
            'title' => $validated['title'] ?? $offer->title,
            'description' => $validated['description'] ?? $offer->description,
            'valid_from' => $validated['valid_from'] ?? $offer->valid_from,
            'expires_at' => $validated['expires_at'] ?? $offer->expires_at,
            'original_price' => $prices['original'],
            'discounted_price' => $prices['discounted'],
            'discount_percent' => $prices['discount_percent'],
            'offer_image' => $package->thumbnail ?: $station->cover_image ?: $offer->offer_image,
            'is_active' => array_key_exists('is_active', $validated)
                ? (bool) $validated['is_active']
                : $offer->is_active,
        ]);

        $offer->load(['package', 'station'])->loadCount(['bookings']);

        return response()->json([
            'message' => 'تم تحديث العرض',
            'offer' => (new ManagerOfferResource($offer->fresh()))->resolve(),
        ]);
    }

    public function destroy(Request $request, Offer $offer): JsonResponse
    {
        $station = $this->resolveManagerStation($request->user());
        if (! $station || (int) $offer->station_id !== (int) $station->id) {
            return response()->json(['message' => 'العرض غير موجود'], 404);
        }

        $offer->delete();

        return response()->json([
            'message' => 'تم حذف العرض',
        ]);
    }

    private function validateOffer(Request $request, ?Offer $offer = null): array
    {
        $validated = $request->validate([
            'title' => ($offer ? 'sometimes|' : '').'required|string|max:120',
            'name' => 'sometimes|string|max:120',
            'package_id' => ($offer ? 'sometimes|' : '').'required|integer|exists:packages,id',
            'discount_percent' => ($offer ? 'sometimes|' : '').'required|integer|min:0|max:100',
            'description' => 'nullable|string|max:2000',
            'valid_from' => ($offer ? 'sometimes|' : '').'required|date',
            'expires_at' => ($offer ? 'sometimes|' : '').'required|date',
            'is_active' => 'sometimes|boolean',
        ]);

        if (isset($validated['name']) && empty($validated['title'])) {
            $validated['title'] = $validated['name'];
        }

        $validFrom = $validated['valid_from'] ?? $offer?->valid_from?->toDateString();
        $expiresAt = $validated['expires_at'] ?? $offer?->expires_at?->toDateString();

        if ($validFrom && $expiresAt && strtotime($expiresAt) < strtotime($validFrom)) {
            abort(422, 'تاريخ النهاية يجب أن يكون بعد تاريخ البداية');
        }

        return $validated;
    }

    private function resolveStationPackage(int $stationId, int $packageId): Package
    {
        $package = Package::query()
            ->where('station_id', $stationId)
            ->where('is_active', true)
            ->find($packageId);

        abort_unless($package, 422, 'الباقة غير موجودة أو غير مفعّلة');

        return $package;
    }

    /** @return array{original: float, discounted: float, discount_percent: int} */
    private function calculatePrices(Package $package, int $discountPercent): array
    {
        $discountPercent = min(100, max(0, $discountPercent));
        $original = (float) $package->hourly_price;
        $discounted = round($original * (1 - $discountPercent / 100), 2);

        return [
            'original' => $original,
            'discounted' => $discounted,
            'discount_percent' => $discountPercent,
        ];
    }
}
