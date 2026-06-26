<?php

namespace App\Services;

use App\Models\Booking;
use App\Support\BookingStatus;
use Carbon\Carbon;

class PlatformFinanceService
{
    public function __construct(
        private readonly FinancialReportService $reports,
        private readonly PlatformCommissionService $commission,
    ) {}

    /**
     * @return array{
     *     global_rate: float,
     *     year: int,
     *     month: int,
     *     total_commissions: float,
     *     total_app_gross_revenue: float,
     *     total_app_bookings: int
     * }
     */
    public function commissionSummary(int $year, int $month): array
    {
        $rows = $this->appRevenueRows($year, $month);

        return [
            'global_rate' => $this->commission->globalRate(),
            'year' => $year,
            'month' => $month,
            'total_commissions' => round((float) $rows->sum(fn (array $row) => $row['commission_amount']), 2),
            'total_app_gross_revenue' => round((float) $rows->sum(fn (array $row) => $row['gross_amount']), 2),
            'total_app_bookings' => $rows->count(),
        ];
    }

    /**
     * @return \Illuminate\Support\Collection<int, array{
     *     booking: Booking,
     *     recognized_at: Carbon,
     *     gross_amount: float,
     *     commission_amount: float,
     *     hall_net: float
     * }>
     */
    private function appRevenueRows(int $year, int $month)
    {
        return Booking::query()
            ->where('payment_status', 'paid')
            ->whereIn('booking_type', ['regular', 'offer'])
            ->where('booking_source', 'mobile_app')
            ->whereNotIn('booking_status', BookingStatus::cancelledStatuses())
            ->with(['station', 'package'])
            ->get()
            ->map(function (Booking $booking) {
                $recognizedAt = $this->reports->revenueRecognizedAt($booking);
                if (! $recognizedAt) {
                    return null;
                }

                return [
                    'booking' => $booking,
                    'recognized_at' => $recognizedAt,
                    'gross_amount' => (float) $booking->total_price,
                    'commission_amount' => (float) $booking->platform_commission_amount,
                    'hall_net' => $this->commission->hallNetRevenue($booking),
                ];
            })
            ->filter()
            ->filter(fn (array $row) => (int) $row['recognized_at']->year === $year
                && (int) $row['recognized_at']->month === $month)
            ->values();
    }
}
