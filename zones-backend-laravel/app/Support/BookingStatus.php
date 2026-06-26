<?php

namespace App\Support;

final class BookingStatus
{
    public const PENDING = 'pending';

    public const CONFIRMED = 'confirmed';

    public const CANCELLED = 'cancelled';

    public const CANCELLED_MAINTENANCE = 'cancelled_maintenance';

    public const COMPLETED = 'completed';

    public const EXPIRED = 'expired';

  /** @return list<string> */
    public static function cancelledStatuses(): array
    {
        return [self::CANCELLED, self::CANCELLED_MAINTENANCE];
    }

  /** @return list<string> */
    public static function inactiveStatuses(): array
    {
        return [...self::cancelledStatuses(), self::COMPLETED, self::EXPIRED];
    }

    public static function isCancelled(string $status): bool
    {
        return in_array($status, self::cancelledStatuses(), true);
    }
}
