<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class Tournament extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'station_id',
        'title',
        'game_name',
        'game_emoji',
        'cover_image',
        'start_date',
        'end_date',
        'registration_deadline',
        'prize_summary',
        'entry_fee',
        'match_rules',
        'delay_minutes',
        'withdrawal_rule',
        'status',
        'max_participants',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'start_date' => 'datetime',
            'end_date' => 'datetime',
            'registration_deadline' => 'datetime',
            'entry_fee' => 'decimal:2',
            'is_active' => 'boolean',
        ];
    }

    public function registeredParticipantsCount(): int
    {
        return $this->participants()->where('status', 'registered')->count();
    }

    public function isRegistrationOpen(): bool
    {
        if (! $this->registration_deadline) {
            return ! in_array($this->status, ['completed', 'cancelled'], true);
        }

        return now()->lte($this->registration_deadline)
            && ! in_array($this->status, ['completed', 'cancelled'], true);
    }

    public function isFull(): bool
    {
        return $this->registeredParticipantsCount() >= (int) $this->max_participants;
    }

    public function station(): BelongsTo
    {
        return $this->belongsTo(Station::class);
    }

    public function participants(): HasMany
    {
        return $this->hasMany(TournamentParticipant::class);
    }

    public function matches(): HasMany
    {
        return $this->hasMany(TournamentMatch::class);
    }
}
