<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\TournamentResource;
use App\Models\Tournament;
use App\Models\TournamentParticipant;
use App\Support\CustomerTournamentParticipationMapper;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TournamentController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = Tournament::query()
            ->where('is_active', true)
            ->whereNotNull('registration_deadline')
            ->whereNotIn('status', ['cancelled'])
            ->with(['station', 'participants', 'matches.player1', 'matches.player2'])
            ->orderByDesc('start_date');

        if ($request->filled('station_id')) {
            $query->where('station_id', $request->integer('station_id'));
        }

        if ($request->filled('lounge_id')) {
            $query->where('station_id', $request->integer('lounge_id'));
        }

        return response()->json(
            TournamentResource::collection($query->get())->resolve()
        );
    }

    public function show(Request $request, Tournament $tournament): JsonResponse
    {
        abort_unless($tournament->is_active, 404);
        abort_unless($tournament->registration_deadline !== null, 404);

        $tournament->load(['station', 'participants', 'matches.player1', 'matches.player2']);

        return response()->json(
            (new TournamentResource($tournament))->resolve()
        );
    }

    public function myRegistrations(Request $request): JsonResponse
    {
        $scope = $request->query('scope', 'all');

        return response()->json([
            'registrations' => $this->registrationRows($request->user(), $scope),
        ]);
    }

    public function myActiveRegistrations(Request $request): JsonResponse
    {
        return response()->json([
            'registrations' => $this->registrationRows($request->user(), 'active'),
        ]);
    }

    public function myParticipationHistory(Request $request): JsonResponse
    {
        return response()->json([
            'registrations' => $this->registrationRows($request->user(), 'completed'),
        ]);
    }

    /**
     * @return \Illuminate\Support\Collection<int, array<string, mixed>>
     */
    private function registrationRows($user, string $scope)
    {
        $query = TournamentParticipant::query()
            ->where('user_id', $user->id)
            ->with(['tournament.station', 'tournament.matches.player1', 'tournament.matches.player2'])
            ->orderByDesc('updated_at');

        if ($scope === 'active') {
            $query->where('status', 'registered')
                ->whereHas(
                    'tournament',
                    fn ($q) => $q->whereNotIn('status', ['completed', 'cancelled'])
                );
        } elseif ($scope === 'completed') {
            $query->where('status', 'registered')
                ->whereHas(
                    'tournament',
                    fn ($q) => $q->where('status', 'completed')
                );
        }

        return $query->get()
            ->map(fn (TournamentParticipant $p) => CustomerTournamentParticipationMapper::toArray($p))
            ->filter(fn (array $row) => $row !== [])
            ->values();
    }

    public function bracket(Request $request, Tournament $tournament): JsonResponse
    {
        abort_unless($tournament->is_active, 404);

        $user = $request->user();
        $participated = $tournament->participants()
            ->where('user_id', $user->id)
            ->where('status', 'registered')
            ->exists();

        abort_unless($participated || in_array($tournament->status, ['completed', 'ongoing'], true), 403);

        $tournament->load(['station', 'participants', 'matches.player1', 'matches.player2']);

        return response()->json([
            'tournament' => (new TournamentResource($tournament))->resolve(),
        ]);
    }

    public function register(Request $request, Tournament $tournament): JsonResponse
    {
        abort_unless($tournament->is_active, 404);
        abort_if(in_array($tournament->status, ['completed', 'cancelled'], true), 422);

        if (! $tournament->isRegistrationOpen()) {
            return response()->json([
                'message' => 'انتهى موعد التسجيل في هذه البطولة',
            ], 422);
        }

        $user = $request->user();
        $validated = $request->validate([
            'player_name' => 'nullable|string|max:120',
        ]);

        $playerName = $validated['player_name'] ?? $user->full_name ?? $user->name;

        if ($tournament->isFull()) {
            return response()->json([
                'message' => 'اكتمل عدد المشاركين في هذه البطولة',
            ], 422);
        }

        $existing = $tournament->participants()
            ->where('user_id', $user->id)
            ->first();

        if ($existing && $existing->status === 'registered') {
            return response()->json([
                'message' => 'أنت مسجل بالفعل في هذه البطولة',
                'participant' => [
                    'id' => (string) $existing->id,
                    'name' => $existing->name,
                ],
            ], 409);
        }

        if ($existing && $existing->status === 'withdrawn') {
            $existing->update([
                'status' => 'registered',
                'name' => $playerName,
                'registered_at' => now(),
                'withdrawn_at' => null,
            ]);
            $participant = $existing->fresh();
        } else {
            $participant = TournamentParticipant::create([
                'tournament_id' => $tournament->id,
                'user_id' => $user->id,
                'name' => $playerName,
                'status' => 'registered',
                'registered_at' => now(),
            ]);
        }

        $tournament->load(['station', 'participants', 'matches.player1', 'matches.player2']);

        return response()->json([
            'message' => 'تم تأكيد اشتراكك في البطولة',
            'tournament' => (new TournamentResource($tournament))->resolve(),
            'participant' => [
                'id' => (string) $participant->id,
                'name' => $participant->name,
                'status' => $participant->status,
            ],
        ], 201);
    }

    public function unregister(Request $request, Tournament $tournament): JsonResponse
    {
        abort_unless($tournament->is_active, 404);

        if (! $tournament->isRegistrationOpen()) {
            return response()->json([
                'message' => 'انتهى موعد الانسحاب من هذه البطولة',
            ], 422);
        }

        $user = $request->user();

        $participant = $tournament->participants()
            ->where('user_id', $user->id)
            ->where('status', 'registered')
            ->first();

        if (! $participant) {
            return response()->json([
                'message' => 'لست مسجلاً في هذه البطولة',
            ], 404);
        }

        $participant->update([
            'status' => 'withdrawn',
            'withdrawn_at' => now(),
        ]);

        $tournament->load(['station', 'participants', 'matches.player1', 'matches.player2']);

        return response()->json([
            'message' => 'تم الانسحاب من البطولة',
            'tournament' => (new TournamentResource($tournament))->resolve(),
        ]);
    }
}
