<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class Package extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'station_id',
        'name',
        'slug',
        'package_type',
        'hourly_price',
        'minimum_hours',
        'maximum_hours',
        'description',
        'thumbnail',
        'is_active',
        'average_rating',
        'ratings_count',
        'notes',
    ];

    protected function casts(): array
    {
        return [
            'hourly_price' => 'decimal:2',
            'average_rating' => 'decimal:2',
            'is_active' => 'boolean',
        ];
    }

    public function station(): BelongsTo
    {
        return $this->belongsTo(Station::class);
    }

    public function devices(): HasMany
    {
        return $this->hasMany(Device::class);
    }

    public function offers(): HasMany
    {
        return $this->hasMany(Offer::class);
    }

    public function deviceRatings(): HasMany
    {
        return $this->hasMany(DeviceRating::class);
    }
}
