<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class TournamentParticipant extends Model
{
    protected $fillable = [
        'tournament_id',
        'user_id',
        'name',
        'avatar_url',
        'status',
        'registered_at',
        'withdrawn_at',
    ];

    protected function casts(): array
    {
        return [
            'registered_at' => 'datetime',
            'withdrawn_at' => 'datetime',
        ];
    }

    public function tournament(): BelongsTo
    {
        return $this->belongsTo(Tournament::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function matchesAsPlayer1(): HasMany
    {
        return $this->hasMany(TournamentMatch::class, 'player1_id');
    }

    public function matchesAsPlayer2(): HasMany
    {
        return $this->hasMany(TournamentMatch::class, 'player2_id');
    }
}
