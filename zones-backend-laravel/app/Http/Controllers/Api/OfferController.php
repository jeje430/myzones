<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\OfferResource;
use App\Models\Offer;
use App\Models\OfferTimeSlot;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class OfferController extends Controller
{
    public function index(): JsonResponse
    {
        $offers = Offer::query()
            ->where('is_active', true)
            ->whereNotNull('station_id')
            ->whereNotNull('package_id')
            ->where('valid_from', '<=', now())
            ->where('expires_at', '>=', now())
            ->with(['timeSlots', 'station', 'package'])
            ->orderByDesc('valid_from')
            ->get();

        return response()->json(
            OfferResource::collection($offers)->resolve()
        );
    }

    public function show(Offer $offer): JsonResponse
    {
        abort_unless($offer->is_active, 404);
        abort_unless($offer->package_id && $offer->station_id, 404);

        $offer->load(['timeSlots', 'station', 'package']);

        return response()->json(
            (new OfferResource($offer))->resolve()
        );
    }

    public function bookSlot(Request $request, Offer $offer, OfferTimeSlot $slot): JsonResponse
    {
        abort_unless($offer->is_active, 404);
        abort_unless($offer->package_id && $offer->station_id, 404);
        abort_unless($slot->offer_id === $offer->id, 404);
        abort_unless($slot->is_available, 422, 'هذا الموعد غير متاح');

        $slot->update(['is_available' => false]);

        $bookingId = 'BK-'.now()->format('YmdHis').'-'.$slot->id;

        return response()->json([
            'message' => 'تم تأكيد الحجز',
            'booking_id' => $bookingId,
            'final_price' => (float) $offer->discounted_price,
        ], 201);
    }
}
