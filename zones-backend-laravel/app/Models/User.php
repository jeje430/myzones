<?php

namespace App\Models;

use App\Services\TenantResolver;
use Laravel\Sanctum\HasApiTokens;
use Spatie\Permission\Traits\HasRoles;
use Illuminate\Notifications\Notifiable;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, HasRoles, Notifiable, SoftDeletes;

    protected $guard_name = 'web';

    protected $fillable = [
        'full_name',
        'phone',
        'profile_image',
        'email',
        'password',
        'google_id',
        'account_status',
        'station_id',
        'work_shift',
        'loyalty_points_balance',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'loyalty_points_balance' => 'integer',
        ];
    }

    public function station(): BelongsTo
    {
        return $this->belongsTo(Station::class);
    }

  /** الصالة التي يديرها المستخدم (للمديرين). */
    public function managedStation(): HasOne
    {
        return $this->hasOne(Station::class, 'manager_id');
    }

    public function deviceTokens(): HasMany
    {
        return $this->hasMany(DeviceToken::class);
    }

    public function resolvedStationId(): ?int
    {
        return app(TenantResolver::class)->resolveStationId($this);
    }

    public function resolvedStation(): ?Station
    {
        return app(TenantResolver::class)->resolveStation($this);
    }
}
