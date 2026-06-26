<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class HallExpense extends Model
{
    protected $fillable = [
        'station_id',
        'name',
        'amount',
        'is_paid',
        'added_at',
        'paid_at',
        'notes',
        'category',
        'device_fault_id',
        'created_by',
    ];

    protected function casts(): array
    {
        return [
            'amount' => 'decimal:2',
            'is_paid' => 'boolean',
            'added_at' => 'date',
            'paid_at' => 'date',
        ];
    }

    public function station(): BelongsTo
    {
        return $this->belongsTo(Station::class);
    }

    public function deviceFault(): BelongsTo
    {
        return $this->belongsTo(DeviceFault::class);
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }
}
