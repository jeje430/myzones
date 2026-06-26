<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class TournamentMatch extends Model
{
    protected $fillable = [
        'tournament_id',
        'round_index',
        'match_index',
        'round',
        'player1_id',
        'player2_id',
        'score1',
        'score2',
        'scheduled_at',
        'status',
        'winner_id',
    ];

    protected function casts(): array
    {
        return [
            'scheduled_at' => 'datetime',
        ];
    }

    public function tournament(): BelongsTo
    {
        return $this->belongsTo(Tournament::class);
    }

    public function player1(): BelongsTo
    {
        return $this->belongsTo(TournamentParticipant::class, 'player1_id');
    }

    public function player2(): BelongsTo
    {
        return $this->belongsTo(TournamentParticipant::class, 'player2_id');
    }

    public function winner(): BelongsTo
    {
        return $this->belongsTo(TournamentParticipant::class, 'winner_id');
    }
}
