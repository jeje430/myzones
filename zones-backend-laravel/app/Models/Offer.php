<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class Offer extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'station_id',
        'package_id',
        'title',
        'offer_image',
        'description',
        'valid_from',
        'expires_at',
        'original_price',
        'discounted_price',
        'discount_percent',
        'terms',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'valid_from' => 'datetime',
            'expires_at' => 'datetime',
            'original_price' => 'decimal:2',
            'discounted_price' => 'decimal:2',
            'discount_percent' => 'integer',
            'terms' => 'array',
            'is_active' => 'boolean',
        ];
    }

    public function station(): BelongsTo
    {
        return $this->belongsTo(Station::class);
    }

    public function package(): BelongsTo
    {
        return $this->belongsTo(Package::class);
    }

    public function bookings(): HasMany
    {
        return $this->hasMany(Booking::class);
    }

    public function timeSlots(): HasMany
    {
        return $this->hasMany(OfferTimeSlot::class);
    }
}
