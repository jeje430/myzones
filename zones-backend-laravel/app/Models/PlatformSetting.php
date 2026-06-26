<?php

namespace App\Models;

use App\Support\MediaUrl;
use Illuminate\Database\Eloquent\Model;

class PlatformSetting extends Model
{
    public const DEFAULT_POINTS_PER_SESSION = 10;

    public const DEFAULT_MINIMUM_POINTS_REQUIRED = 100;

    public const DEFAULT_PLATFORM_COMMISSION_RATE = 10;

    public const DEFAULT_PLATFORM_NAME = 'منصة إدارة الصالات';

    protected $fillable = [
        'loyalty_points_per_session',
        'loyalty_minimum_points_required',
        'platform_commission_rate',
        'platform_name',
        'platform_logo_path',
    ];

    protected function casts(): array
    {
        return [
            'loyalty_points_per_session' => 'integer',
            'loyalty_minimum_points_required' => 'integer',
            'platform_commission_rate' => 'decimal:2',
        ];
    }

    public static function current(): self
    {
        return static::query()->firstOrCreate(
            ['id' => 1],
            [
                'loyalty_points_per_session' => self::DEFAULT_POINTS_PER_SESSION,
                'loyalty_minimum_points_required' => self::DEFAULT_MINIMUM_POINTS_REQUIRED,
                'platform_commission_rate' => self::DEFAULT_PLATFORM_COMMISSION_RATE,
                'platform_name' => self::DEFAULT_PLATFORM_NAME,
            ],
        );
    }

    public function estimatedSessionsRequired(): int
    {
        $pointsPerSession = max(1, (int) $this->loyalty_points_per_session);
        $minimumRequired = max(1, (int) $this->loyalty_minimum_points_required);

        return (int) ceil($minimumRequired / $pointsPerSession);
    }

    public function toLoyaltyPayload(): array
    {
        return [
            'points_per_completed_session' => (int) $this->loyalty_points_per_session,
            'minimum_points_required' => (int) $this->loyalty_minimum_points_required,
            'estimated_sessions_required' => $this->estimatedSessionsRequired(),
        ];
    }

    public function toCommissionPayload(): array
    {
        return [
            'platform_commission_rate' => round((float) $this->platform_commission_rate, 2),
        ];
    }

    public function toBrandingPayload(): array
    {
        return [
            'platform_name' => $this->platform_name ?: self::DEFAULT_PLATFORM_NAME,
            'logo_url' => MediaUrl::resolve($this->platform_logo_path),
        ];
    }
}
