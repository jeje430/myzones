<?php

namespace App\Services;

use App\Models\Booking;
use App\Models\PlatformSetting;

class PlatformCommissionService
{
    public const MAX_RATE = 100;

    public function globalRate(): float
    {
        return (float) PlatformSetting::current()->platform_commission_rate;
    }

    public function appliesToMobileBooking(string $bookingType, float $total): bool
    {
        return in_array($bookingType, ['regular', 'offer'], true) && $total > 0;
    }

    public function appliesToBooking(Booking $booking): bool
    {
        return $booking->booking_source === 'mobile_app'
            && $this->appliesToMobileBooking((string) $booking->booking_type, (float) $booking->total_price);
    }

    /**
     * @return array{rate: float, amount: float, hall_net: float}
     */
    public function calculateForTotal(float $total, ?float $rate = null): array
    {
        $rate = max(0, min(self::MAX_RATE, $rate ?? $this->globalRate()));
        $amount = round($total * ($rate / 100), 2);
        $hallNet = round(max(0, $total - $amount), 2);

        return [
            'rate' => $rate,
            'amount' => $amount,
            'hall_net' => $hallNet,
        ];
    }

    public function hallNetRevenue(Booking $booking): float
    {
        if ($this->appliesToBooking($booking)) {
            return max(0, (float) $booking->total_price - (float) $booking->platform_commission_amount);
        }

        return (float) $booking->total_price;
    }
}
