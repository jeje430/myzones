<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Package;
use App\Models\Station;
use App\Services\DeviceRatingService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

class DeviceRatingController extends Controller
{
    public function __construct(
        private readonly DeviceRatingService $deviceRatingService,
    ) {}

    public function store(Request $request, Station $station): JsonResponse
    {
        $station->loadMissing('manager');
        abort_unless($station->isCustomerVisible(), 404, 'Hall unavailable');

        $user = $request->user();
        abort_unless($user !== null, 401);
        abort_unless($user->hasRole('customer'), 403);

        $validated = $request->validate([
            'ratings' => 'required|array|min:1',
            'ratings.*.device_id' => 'required|integer|exists:packages,id',
            'ratings.*.rating_value' => 'required|integer|min:1|max:5',
        ]);

        $packageIds = collect($validated['ratings'])->pluck('device_id')->unique();

        $validPackageCount = Package::query()
            ->where('station_id', $station->id)
            ->where('is_active', true)
            ->whereIn('id', $packageIds)
            ->count();

        if ($validPackageCount !== $packageIds->count()) {
            throw ValidationException::withMessages([
                'ratings' => ['واحد أو أكثر من الأجهزة غير موجود أو لا ينتمي لهذه الصالة.'],
            ]);
        }

        $saved = $this->deviceRatingService->upsertBatch($user, $station, $validated['ratings']);

        return response()->json([
            'message' => 'تم إرسال التقييم بنجاح',
            'ratings' => $saved->map(fn ($rating) => [
                'device_id' => (string) $rating->package_id,
                'rating_value' => $rating->rating_value,
                'submitted_at' => $rating->updated_at?->toIso8601String(),
            ])->values()->all(),
        ], 201);
    }
}
