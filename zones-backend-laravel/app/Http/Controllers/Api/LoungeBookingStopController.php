<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Station;
use App\Services\BookingStopService;
use Illuminate\Http\JsonResponse;

class LoungeBookingStopController extends Controller
{
    public function __construct(
        private readonly BookingStopService $bookingStops,
    ) {}

    public function show(Station $station): JsonResponse
    {
        abort_unless(
            $station->is_published && $station->is_active && $station->manager_id !== null,
            404,
        );

        $active = $this->bookingStops->activeForStation($station);

        return response()->json([
            'booking_stop' => $this->bookingStops->publicPayload($active),
            'is_blocked' => $active !== null,
        ]);
    }
}
