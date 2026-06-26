<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

class Station extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'manager_id',
        'name',
        'slug',
        'cover_image',
        'phone',
        'email',
        'city',
        'address',
        'description',
        'latitude',
        'longitude',
        'working_days',
        'opens_at',
        'closes_at',
        'average_rating',
        'reviews_count',
        'map_link',
        'available_services',
        'is_active',
        'bookings_enabled',
        'is_published',
        'published_at',
        'setup_completed_at',
    ];

    protected function casts(): array
    {
        return [
            'working_days' => 'array',
            'available_services' => 'array',
            'is_active' => 'boolean',
            'bookings_enabled' => 'boolean',
            'is_published' => 'boolean',
            'published_at' => 'datetime',
            'setup_completed_at' => 'datetime',
        ];
    }

    public function manager(): BelongsTo
    {
        return $this->belongsTo(User::class, 'manager_id');
    }

    public function packages(): \Illuminate\Database\Eloquent\Relations\HasMany
    {
        return $this->hasMany(Package::class);
    }

    public function devices(): \Illuminate\Database\Eloquent\Relations\HasMany
    {
        return $this->hasMany(Device::class);
    }

    public function reviews(): \Illuminate\Database\Eloquent\Relations\HasMany
    {
        return $this->hasMany(Review::class);
    }

    public function comments(): \Illuminate\Database\Eloquent\Relations\HasMany
    {
        return $this->hasMany(StationComment::class);
    }

    public function offers(): \Illuminate\Database\Eloquent\Relations\HasMany
    {
        return $this->hasMany(Offer::class);
    }

    public function bookingStops(): \Illuminate\Database\Eloquent\Relations\HasMany
    {
        return $this->hasMany(StationBookingStop::class);
    }

    public function tournaments(): \Illuminate\Database\Eloquent\Relations\HasMany
    {
        return $this->hasMany(Tournament::class);
    }

    public function bookings(): \Illuminate\Database\Eloquent\Relations\HasMany
    {
        return $this->hasMany(Booking::class);
    }
}
