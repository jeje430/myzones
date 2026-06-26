<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CustomerNotification;
use App\Models\User;
use App\Services\LoyaltyService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CustomerLoyaltyController extends Controller
{
    public function __construct(
        private readonly LoyaltyService $loyalty,
    ) {}

    public function status(Request $request): JsonResponse
    {
        $user = $this->customer($request);

        return response()->json($this->loyalty->statusPayload($user->fresh()));
    }

    public function markNotificationRead(Request $request, CustomerNotification $notification): JsonResponse
    {
        $user = $this->customer($request);
        $this->loyalty->markNotificationRead($user, $notification);

        return response()->json([
            'message' => 'Notification marked as read',
            'status' => $this->loyalty->statusPayload($user->fresh()),
        ]);
    }

    private function customer(Request $request): User
    {
        $user = $request->user();
        if (! $user instanceof User) {
            abort(401);
        }

        return $user;
    }
}
