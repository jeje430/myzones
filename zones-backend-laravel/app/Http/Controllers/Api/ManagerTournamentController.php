<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ResolvesManagerStation;
use App\Http\Controllers\Api\Concerns\ResolvesStaffStation;
use App\Http\Controllers\Controller;
use App\Http\Resources\TournamentParticipantResource;
use App\Http\Resources\TournamentResource;
use App\Models\Tournament;
use App\Models\User;
use App\Support\StationImageStorage;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class ManagerTournamentController extends Controller
{
    use ResolvesManagerStation;
    use ResolvesStaffStation;

    protected function resolveTournamentStation(User $user): ?\App\Models\Station
    {
        if ($user->hasRole('manager')) {
            return $this->resolveManagerStation($user);
        }

        return $this->resolveStaffStation($user);
    }

    public function index(Request $request): JsonResponse
    {
        $station = $this->resolveTournamentStation($request->user());
        if (! $station) {
            return $this->managerStationMissingResponse();
        }

        $tournaments = Tournament::query()
            ->where('station_id', $station->id)
            ->whereNotNull('registration_deadline')
            ->with(['participants.user'])
            ->withCount([
                'participants as registered_participants_count' => fn ($q) => $q->where('status', 'registered'),
            ])
            ->orderByDesc('start_date')
            ->get();

        return response()->json([
            'tournaments' => $tournaments->map(fn (Tournament $t) => $this->managerPayload($t))->values(),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $station = $this->resolveManagerStation($request->user());
        if (! $station) {
            return $this->managerStationMissingResponse();
        }

        $validated = $this->validatePayload($request);

        $tournament = DB::transaction(function () use ($station, $validated, $request) {
            $coverPath = null;
            if (! empty($validated['cover_image'])) {
                $coverPath = StationImageStorage::storeCoverImage($validated['cover_image']);
            }

            return Tournament::create([
                'station_id' => $station->id,
                'title' => $validated['title'],
                'game_name' => $validated['game_name'],
                'game_emoji' => $validated['game_emoji'] ?? '🎮',
                'cover_image' => $coverPath,
                'start_date' => $validated['start_date'],
                'end_date' => $validated['end_date'],
                'registration_deadline' => $validated['registration_deadline'],
                'prize_summary' => $validated['prize_summary'] ?? '',
                'entry_fee' => $validated['entry_fee'] ?? 0,
                'delay_minutes' => $validated['delay_minutes'],
                'withdrawal_rule' => $validated['withdrawal_rule'] ?? null,
                'match_rules' => $validated['match_rules'],
                'status' => 'upcoming',
                'max_participants' => $validated['max_participants'],
                'is_active' => true,
            ]);
        });

        $tournament->load(['participants.user'])
            ->loadCount([
                'participants as registered_participants_count' => fn ($q) => $q->where('status', 'registered'),
            ]);

        return response()->json([
            'message' => 'تم حفظ البطولة',
            'tournament' => $this->managerPayload($tournament),
        ], 201);
    }

    public function show(Request $request, Tournament $tournament): JsonResponse
    {
        $station = $this->resolveTournamentStation($request->user());
        if (! $station || (int) $tournament->station_id !== (int) $station->id) {
            abort(403);
        }

        $tournament->load(['participants.user'])
            ->loadCount([
                'participants as registered_participants_count' => fn ($q) => $q->where('status', 'registered'),
            ]);

        return response()->json([
            'tournament' => $this->managerPayload($tournament),
        ]);
    }

    public function update(Request $request, Tournament $tournament): JsonResponse
    {
        $station = $this->resolveManagerStation($request->user());
        if (! $station || (int) $tournament->station_id !== (int) $station->id) {
            abort(403);
        }

        abort_if($tournament->status === 'cancelled', 422, 'لا يمكن تعديل بطولة ملغاة');

        $validated = $this->validatePayload($request);

        $tournament = DB::transaction(function () use ($tournament, $validated) {
            $coverPath = $tournament->cover_image;
            if (array_key_exists('cover_image', $validated)) {
                if ($validated['cover_image'] === null || $validated['cover_image'] === '') {
                    if ($coverPath) {
                        StationImageStorage::deleteCover($coverPath);
                    }
                    $coverPath = null;
                } elseif (str_starts_with($validated['cover_image'], 'data:image')) {
                    $coverPath = StationImageStorage::storeCoverImage(
                        $validated['cover_image'],
                        $coverPath
                    );
                }
            }

            $tournament->update([
                'title' => $validated['title'],
                'game_name' => $validated['game_name'],
                'game_emoji' => $validated['game_emoji'] ?? $tournament->game_emoji,
                'cover_image' => $coverPath,
                'start_date' => $validated['start_date'],
                'end_date' => $validated['end_date'],
                'registration_deadline' => $validated['registration_deadline'],
                'prize_summary' => $validated['prize_summary'] ?? '',
                'entry_fee' => $validated['entry_fee'] ?? 0,
                'delay_minutes' => $validated['delay_minutes'],
                'withdrawal_rule' => $validated['withdrawal_rule'] ?? null,
                'match_rules' => $validated['match_rules'],
                'max_participants' => $validated['max_participants'],
            ]);

            return $tournament->fresh();
        });

        $tournament->load(['participants.user'])
            ->loadCount([
                'participants as registered_participants_count' => fn ($q) => $q->where('status', 'registered'),
            ]);

        return response()->json([
            'message' => 'تم تحديث البطولة',
            'tournament' => $this->managerPayload($tournament),
        ]);
    }

    public function cancel(Request $request, Tournament $tournament): JsonResponse
    {
        $station = $this->resolveManagerStation($request->user());
        if (! $station || (int) $tournament->station_id !== (int) $station->id) {
            abort(403);
        }

        if ($tournament->status === 'cancelled') {
            return response()->json(['message' => 'البطولة ملغاة مسبقاً'], 422);
        }

        $tournament->update([
            'status' => 'cancelled',
            'is_active' => false,
        ]);

        $tournament->load(['participants.user'])
            ->loadCount([
                'participants as registered_participants_count' => fn ($q) => $q->where('status', 'registered'),
            ]);

        return response()->json([
            'message' => 'تم إلغاء البطولة',
            'tournament' => $this->managerPayload($tournament),
        ]);
    }

    public function participants(Request $request, Tournament $tournament): JsonResponse
    {
        $station = $this->resolveTournamentStation($request->user());
        if (! $station || (int) $tournament->station_id !== (int) $station->id) {
            abort(403);
        }

        $participants = $tournament->participants()
            ->with('user')
            ->orderByDesc('created_at')
            ->get()
            ->map(fn ($p) => [
                'id' => (string) $p->id,
                'name' => $p->name,
                'email' => $p->user?->email,
                'registered_at' => ($p->registered_at ?? $p->created_at)?->toIso8601String(),
                'status' => $p->status,
                'status_label' => $p->status === 'withdrawn' ? 'منسحب' : 'مسجل',
            ])
            ->values();

        return response()->json([
            'tournament_id' => (string) $tournament->id,
            'participants' => $participants,
        ]);
    }

    /**
     * @return array<string, mixed>
     */
    private function managerPayload(Tournament $tournament): array
    {
        $resource = (new TournamentResource($tournament))->resolve();

        return array_merge($resource, [
            'withdrawal_rule' => $tournament->withdrawal_rule,
            'delay_minutes' => (int) $tournament->delay_minutes,
            'registered_participants_count' => (int) ($tournament->registered_participants_count
                ?? $tournament->participants()->where('status', 'registered')->count()),
        ]);
    }

    /**
     * @return array<string, mixed>
     */
    private function validatePayload(Request $request): array
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'game_name' => 'required|string|max:255',
            'game_emoji' => 'nullable|string|max:8',
            'max_participants' => 'required|integer|in:8,16',
            'prize_summary' => 'nullable|string|max:500',
            'start_date' => 'required|date',
            'end_date' => 'required|date|after_or_equal:start_date',
            'registration_deadline' => 'required|date',
            'delay_minutes' => 'required|integer|min:0|max:180',
            'withdrawal_rule' => 'nullable|string|max:255',
            'entry_fee' => 'nullable|numeric|min:0',
            'cover_image' => 'nullable|string',
            'match_rules' => 'required|string|max:5000',
        ]);

        $deadline = Carbon::parse($validated['registration_deadline']);
        $latestAllowed = Carbon::parse($validated['start_date'])->endOfDay();

        if ($deadline->gt($latestAllowed)) {
            throw ValidationException::withMessages([
                'registration_deadline' => [
                    'يجب أن يكون موعد انتهاء المشاركة في أو قبل يوم بداية البطولة.',
                ],
            ]);
        }

        return $validated;
    }
}
