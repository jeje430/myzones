<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\StationBroadcast;
use App\Models\User;
use App\Services\NotificationTargetingService;
use App\Support\NotificationTargetAudience;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class ManagerBroadcastController extends Controller
{
    public function __construct(
        private readonly NotificationTargetingService $targeting,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $user = $this->manager($request);
        $stationId = $user->resolvedStationId();

        if (! $stationId) {
            return response()->json(['message' => 'لا توجد صالة مرتبطة'], 404);
        }

        $status = $request->query('status', 'active');
        if ($status === 'archived') {
            $status = 'stopped';
        }

        $broadcasts = StationBroadcast::query()
            ->where('station_id', $stationId)
            ->when($status === 'active', fn ($q) => $q->active())
            ->when($status === 'stopped', fn ($q) => $q->archived())
            ->when($status !== 'all' && ! in_array($status, ['active', 'stopped'], true), fn ($q) => $q->where('status', $status))
            ->orderByDesc('created_at')
            ->get()
            ->map(fn (StationBroadcast $b) => $this->mapBroadcast($b));

        return response()->json(['broadcasts' => $broadcasts]);
    }

    public function store(Request $request): JsonResponse
    {
        $user = $this->manager($request);
        $station = $user->resolvedStation();

        if (! $station) {
            return response()->json(['message' => 'لا توجد صالة مرتبطة'], 404);
        }

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'situation_description' => 'required|string|max:5000',
            'target_audience' => 'required|string|max:64',
            'severity' => 'nullable|in:low,medium,high,critical',
            'alternative_instructions' => 'nullable|string|max:2000',
        ]);

        try {
            $validated['target_audience'] = NotificationTargetAudience::normalize($validated['target_audience']);
        } catch (\InvalidArgumentException) {
            throw ValidationException::withMessages([
                'target_audience' => ['جمهور مستهدف غير صالح'],
            ]);
        }

        if (! NotificationTargetAudience::isValid($validated['target_audience'])) {
            throw ValidationException::withMessages([
                'target_audience' => ['جمهور مستهدف غير صالح'],
            ]);
        }

        if (! NotificationTargetAudience::isSelectable($validated['target_audience'])) {
            throw ValidationException::withMessages([
                'target_audience' => ['يجب اختيار مستهدف محدد: الجميع، الزبون، موظف الاستقبال، أو موظف الصيانة'],
            ]);
        }

        $result = DB::transaction(function () use ($validated, $user, $station) {
            $broadcast = StationBroadcast::create([
                'station_id' => $station->id,
                'created_by' => $user->id,
                'name' => $validated['name'],
                'body' => $validated['situation_description'],
                'target_audience' => $validated['target_audience'],
                'severity' => $validated['severity'] ?? 'medium',
                'status' => 'active',
                'alternative_instructions' => $validated['alternative_instructions'] ?? null,
                'starts_at' => now(),
            ]);

            $broadcast->setRelation('station', $station);
            $delivery = $this->targeting->dispatchBroadcast($broadcast);

            return compact('broadcast', 'delivery');
        });

        return response()->json([
            'message' => 'تم إرسال التنبيه للمستهدفين',
            'broadcast' => $this->mapBroadcast($result['broadcast']),
            'delivery' => $result['delivery'],
        ], 201);
    }

    public function stop(Request $request, StationBroadcast $broadcast): JsonResponse
    {
        return $this->archive($request, $broadcast);
    }

    public function archive(Request $request, StationBroadcast $broadcast): JsonResponse
    {
        $user = $this->manager($request);
        $stationId = $user->resolvedStationId();

        if (! $stationId || (int) $broadcast->station_id !== (int) $stationId) {
            return response()->json(['message' => 'التنبيه غير موجود'], 404);
        }

        if ($broadcast->status !== 'active') {
            throw ValidationException::withMessages([
                'broadcast' => ['التنبيه مؤرشف بالفعل'],
            ]);
        }

        $broadcast->update([
            'status' => 'stopped',
            'ends_at' => now(),
        ]);

        return response()->json([
            'message' => 'تم أرشفة التنبيه',
            'broadcast' => $this->mapBroadcast($broadcast->fresh()),
        ]);
    }

    private function mapBroadcast(StationBroadcast $broadcast): array
    {
        return [
            'id' => $broadcast->id,
            'name' => $broadcast->name,
            'body' => $broadcast->body,
            'situationDescription' => $broadcast->body,
            'targetAudience' => $broadcast->target_audience,
            'target_audience' => $broadcast->target_audience,
            'severity' => $broadcast->severity,
            'status' => $broadcast->status,
            'is_archived' => $broadcast->status === 'stopped',
            'isArchived' => $broadcast->status === 'stopped',
            'alternativeInstructions' => $broadcast->alternative_instructions ?? '',
            'alternative_instructions' => $broadcast->alternative_instructions ?? '',
            'startDate' => $broadcast->starts_at?->toIso8601String(),
            'endDate' => $broadcast->ends_at?->toIso8601String(),
            'createdAt' => $broadcast->created_at?->toIso8601String(),
            'source' => 'api',
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
