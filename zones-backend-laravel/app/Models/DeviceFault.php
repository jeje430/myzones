<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DeviceFault extends Model
{
    protected $fillable = [
        'station_id',
        'device_id',
        'reported_by',
        'fault_type',
        'fault_type_custom',
        'details',
        'status',
        'maintenance_cost',
        'maintenance_employee_name',
        'reported_at',
        'resolved_at',
        'archived',
    ];

    protected function casts(): array
    {
        return [
            'maintenance_cost' => 'decimal:2',
            'reported_at' => 'datetime',
            'resolved_at' => 'datetime',
            'archived' => 'boolean',
        ];
    }

    public function station(): BelongsTo
    {
        return $this->belongsTo(Station::class);
    }

    public function device(): BelongsTo
    {
        return $this->belongsTo(Device::class);
    }

    public function reporter(): BelongsTo
    {
        return $this->belongsTo(User::class, 'reported_by');
    }

    public function isOpen(): bool
    {
        return ! $this->archived && $this->status !== 'resolved';
    }
}
