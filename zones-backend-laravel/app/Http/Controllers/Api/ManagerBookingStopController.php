<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\StationBookingStop;
use App\Models\User;
use App\Services\BookingStopService;
use App\Support\BookingStopReason;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ManagerBookingStopController extends Controller
{
    public function __construct(
        private readonly BookingStopService $bookingStops,
    ) {}

    public function reasons(): JsonResponse
    {
        return response()->json(['reasons' => BookingStopReason::selectable()]);
    }

    public function index(Request $request): JsonResponse
    {
        $stationId = $this->manager($request)->resolvedStationId();
        if (! $stationId) {
            return response()->json(['message' => 'لا توجد صالة مرتبطة'], 404);
        }

        $records = $this->bookingStops->listForStation($stationId)
            ->map(fn (StationBookingStop $row) => $this->mapRecord($row));

        return response()->json([
            'records' => $records,
            'active' => $this->bookingStops->publicPayload(
                $this->bookingStops->activeForStation(
                    $this->manager($request)->resolvedStation(),
                ),
            ),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $user = $this->manager($request);
        $station = $user->resolvedStation();
        if (! $station) {
            return response()->json(['message' => 'لا توجد صالة مرتبطة'], 404);
        }

        $validated = $request->validate([
            'reason_key' => 'required|string|max:64',
            'starts_on' => 'required|date_format:Y-m-d',
            'ends_on' => 'nullable|date_format:Y-m-d|after_or_equal:starts_on',
        ]);

        $record = $this->bookingStops->create(
            $station,
            $user->id,
            $validated['reason_key'],
            $validated['starts_on'],
            $validated['ends_on'] ?? null,
        );

        return response()->json([
            'message' => 'تم إيقاف الحجوزات',
            'record' => $this->mapRecord($record),
            'active' => $this->bookingStops->publicPayload($record),
        ], 201);
    }

    public function update(Request $request, StationBookingStop $bookingStop): JsonResponse
    {
        $user = $this->manager($request);
        $stationId = $user->resolvedStationId();

        if (! $stationId || (int) $bookingStop->station_id !== (int) $stationId) {
            return response()->json(['message' => 'السجل غير موجود'], 404);
        }

        $validated = $request->validate([
            'reason_key' => 'required|string|max:64',
            'ends_on' => 'nullable|date_format:Y-m-d',
        ]);

        $record = $this->bookingStops->update(
            $bookingStop,
            $validated['reason_key'],
            $validated['ends_on'] ?? null,
        );

        return response()->json([
            'message' => 'تم تحديث إيقاف الحجوزات',
            'record' => $this->mapRecord($record),
            'active' => $this->bookingStops->publicPayload($record),
        ]);
    }

    public function resume(Request $request, StationBookingStop $bookingStop): JsonResponse
    {
        $user = $this->manager($request);
        $stationId = $user->resolvedStationId();

        if (! $stationId || (int) $bookingStop->station_id !== (int) $stationId) {
            return response()->json(['message' => 'السجل غير موجود'], 404);
        }

        $record = $this->bookingStops->resume($bookingStop);

        return response()->json([
            'message' => 'تم استئناف الحجوزات',
            'record' => $this->mapRecord($record),
            'active' => null,
        ]);
    }

    public function destroy(Request $request, StationBookingStop $bookingStop): JsonResponse
    {
        $user = $this->manager($request);
        $stationId = $user->resolvedStationId();

        if (! $stationId || (int) $bookingStop->station_id !== (int) $stationId) {
            return response()->json(['message' => 'السجل غير موجود'], 404);
        }

        $this->bookingStops->delete($bookingStop);

        return response()->json(['message' => 'تم حذف السجل']);
    }

    /**
     * @return array<string, mixed>
     */
    private function mapRecord(StationBookingStop $row): array
    {
        return [
            'id' => $row->id,
            'code' => sprintf('H-%04d', $row->id),
            'reasonKey' => $row->reason_key,
            'reason_key' => $row->reason_key,
            'reasonLabel' => BookingStopReason::label($row->reason_key),
            'reason' => BookingStopReason::label($row->reason_key),
            'startsOn' => $row->starts_on?->format('Y-m-d'),
            'starts_on' => $row->starts_on?->format('Y-m-d'),
            'startDate' => $row->starts_on?->format('Y-m-d H:i'),
            'endsOn' => $row->ends_on?->format('Y-m-d'),
            'ends_on' => $row->ends_on?->format('Y-m-d'),
            'endDate' => $row->ended_at?->format('Y-m-d H:i') ?? ($row->ends_on?->format('Y-m-d') ?: ''),
            'status' => $row->status === 'active' ? 'active' : 'ended',
            'isActive' => $row->status === 'active',
            'message' => $row->status === 'active' ? $this->bookingStops->blockMessage($row) : null,
        ];
    }

    private function manager(Request $request): User
    {
        $user = $request->user();
        if (! $user instanceof User || ! $user->hasRole('manager')) {
            abort(403, 'غير مصرح');
        }

        return $user;
    }
}
