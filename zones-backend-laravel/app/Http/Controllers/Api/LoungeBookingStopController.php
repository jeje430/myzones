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
        $station->loadMissing('manager');
        abort_unless($station->isCustomerVisible(), 404, 'Hall unavailable');

        $active = $this->bookingStops->activeForStation($station);

        return response()->json([
            'booking_stop' => $this->bookingStops->publicPayload($active),
            'is_blocked' => $active !== null,
        ]);
    }
}
