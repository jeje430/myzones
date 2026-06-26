<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class TournamentMatchResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => (string) $this->id,
            'round' => $this->round,
            'player1' => $this->player1
                ? (new TournamentParticipantResource($this->player1))->resolve()
                : null,
            'player2' => $this->player2
                ? (new TournamentParticipantResource($this->player2))->resolve()
                : null,
            'score1' => $this->score1,
            'score2' => $this->score2,
            'team1_score' => $this->score1,
            'team2_score' => $this->score2,
            'scheduled_at' => $this->scheduled_at?->toIso8601String(),
            'status' => $this->status,
            'winner_id' => $this->winner_id ? (string) $this->winner_id : null,
        ];
    }
}
