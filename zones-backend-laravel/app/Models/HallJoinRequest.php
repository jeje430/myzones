<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class HallJoinRequest extends Model
{
    protected $fillable = [
        'hall_name',
        'address',
        'city',
        'map_link',
        'manager_email',
        'manager_name',
        'commercial_phone',
        'images',
        'status',
        'commission_rate',
        'admin_notes',
        'rejection_reason',
        'station_id',
        'accepted_at',
        'rejected_at',
    ];

    protected function casts(): array
    {
        return [
            'images' => 'array',
            'commission_rate' => 'decimal:2',
            'accepted_at' => 'datetime',
            'rejected_at' => 'datetime',
        ];
    }

    public function station(): BelongsTo
    {
        return $this->belongsTo(Station::class);
    }
}
