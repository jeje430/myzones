<?php

namespace App\Services;

use App\Models\Booking;
use App\Models\HallExpense;
use App\Models\PaymentTransaction;
use App\Support\BookingStatus;
use Carbon\Carbon;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Collection;

class FinancialReportService
{
    /** @var list<string> */
    private const REVENUE_BOOKING_TYPES = ['regular', 'offer'];

    public function __construct(
        private readonly PlatformCommissionService $commission,
    ) {}

    public function recognizedRevenueQuery(int $stationId): Builder
    {
        return Booking::query()
            ->where('station_id', $stationId)
            ->where('payment_status', 'paid')
            ->whereIn('booking_type', self::REVENUE_BOOKING_TYPES)
            ->whereNotIn('booking_status', BookingStatus::cancelledStatuses());
    }

    public function revenueRecognizedAt(Booking $booking): ?Carbon
    {
        if ($booking->payment_method === 'online') {
            $paidAt = PaymentTransaction::query()
                ->where('booking_id', $booking->id)
                ->where('status', 'paid')
                ->orderByDesc('paid_at')
                ->value('paid_at');

            if ($paidAt) {
                return Carbon::parse($paidAt);
            }

            return $booking->updated_at;
        }

        if ($booking->payment_method === 'cash') {
            return $booking->checked_in_at;
        }

        return null;
    }

    /**
     * @return Collection<int, array{booking: Booking, recognized_at: Carbon, amount: float}>
     */
    public function recognizedRevenueRows(int $stationId): Collection
    {
        return $this->recognizedRevenueQuery($stationId)
            ->with(['package', 'device'])
            ->get()
            ->map(function (Booking $booking) {
                $recognizedAt = $this->revenueRecognizedAt($booking);

                if (! $recognizedAt) {
                    return null;
                }

                return [
                    'booking' => $booking,
                    'recognized_at' => $recognizedAt,
                    'amount' => $this->commission->hallNetRevenue($booking),
                    'gross_amount' => (float) $booking->total_price,
                    'commission_amount' => (float) $booking->platform_commission_amount,
                ];
            })
            ->filter()
            ->values();
    }

    public function sumRevenueOnDate(int $stationId, string $isoDate): float
    {
        return (float) $this->recognizedRevenueRows($stationId)
            ->filter(fn (array $row) => $row['recognized_at']->toDateString() === $isoDate)
            ->sum('amount');
    }

    public function sumRevenueInMonth(int $stationId, int $year, int $month): float
    {
        return (float) $this->recognizedRevenueRows($stationId)
            ->filter(fn (array $row) => $this->matchesMonth($row['recognized_at'], $year, $month))
            ->sum('amount');
    }

    /**
     * @return array{today_total: float, yesterday_total: float, delta_pct: float}
     */
    public function todayRevenueSummary(int $stationId, ?Carbon $reference = null): array
    {
        $reference ??= now();
        $today = $reference->toDateString();
        $yesterday = $reference->copy()->subDay()->toDateString();

        $todayTotal = $this->sumRevenueOnDate($stationId, $today);
        $yesterdayTotal = $this->sumRevenueOnDate($stationId, $yesterday);

        $deltaPct = 0.0;
        if ($yesterdayTotal > 0) {
            $deltaPct = (($todayTotal - $yesterdayTotal) / $yesterdayTotal) * 100;
        } elseif ($todayTotal > 0) {
            $deltaPct = 100.0;
        }

        return [
            'today_total' => round($todayTotal, 2),
            'yesterday_total' => round($yesterdayTotal, 2),
            'delta_pct' => round($deltaPct, 2),
        ];
    }

    /**
     * @return list<array{label: string, revenue: float}>
     */
    public function buildRevenueDailySeries(int $stationId, int $year, int $month): array
    {
        $days = cal_days_in_month(CAL_GREGORIAN, $month, $year);
        $buckets = [];

        for ($day = 1; $day <= $days; $day++) {
            $iso = sprintf('%04d-%02d-%02d', $year, $month, $day);
            $buckets[] = [
                'label' => (string) $day,
                'revenue' => round($this->sumRevenueOnDate($stationId, $iso), 2),
            ];
        }

        return $buckets;
    }

    /**
     * @return list<array{label: string, revenue: float}>
     */
    public function buildRevenueWeeklySeries(int $stationId, int $year, int $month): array
    {
        $daily = $this->buildRevenueDailySeries($stationId, $year, $month);
        $out = [];

        for ($week = 0; $week < 4; $week++) {
            $slice = array_slice($daily, $week * 7, 7);
            $out[] = [
                'label' => 'الأسبوع '.($week + 1),
                'revenue' => round(collect($slice)->sum('revenue'), 2),
            ];
        }

        return $out;
    }

    /**
     * @return list<array{label: string, revenue: float}>
     */
    public function buildRevenueMonthlySeries(int $stationId, int $year): array
    {
        $months = [
            'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
            'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
        ];

        return collect($months)->map(function (string $name, int $index) use ($stationId, $year) {
            return [
                'label' => mb_substr($name, 0, 3),
                'revenue' => round($this->sumRevenueInMonth($stationId, $year, $index + 1), 2),
            ];
        })->all();
    }

    /**
     * @return list<array{name: string, key: string, value: float, color: string}>
     */
    public function buildRevenueSourceBreakdown(int $stationId, int $year, int $month): array
    {
        $rows = $this->recognizedRevenueRows($stationId)
            ->filter(fn (array $row) => $this->matchesMonth($row['recognized_at'], $year, $month));

        $total = (float) $rows->sum('amount');

        if ($total <= 0) {
            return [
                ['name' => 'تطبيق الزبون', 'key' => 'app', 'value' => 0, 'color' => '#a78bfa'],
                ['name' => 'حجز يدوي', 'key' => 'manual', 'value' => 0, 'color' => '#fbbf24'],
            ];
        }

        $appTotal = (float) $rows
            ->filter(fn (array $row) => $row['booking']->booking_source === 'mobile_app')
            ->sum('amount');

        return [
            [
                'name' => 'تطبيق الزبون',
                'key' => 'app',
                'value' => round($appTotal, 2),
                'color' => '#a78bfa',
            ],
            [
                'name' => 'حجز يدوي',
                'key' => 'manual',
                'value' => round(max(0, $total - $appTotal), 2),
                'color' => '#fbbf24',
            ],
        ];
    }

    /**
     * @return list<array{name: string, key: string, package_id: int|null, sessions_count: int, percentage: float, color: string}>
     */
    public function buildPackageUsageBreakdown(int $stationId, int $year, int $month, string $period = 'monthly'): array
    {
        $colors = ['#a78bfa', '#22d3ee', '#34d399', '#fbbf24', '#f97316', '#6B5478', '#ec4899', '#94a3b8'];
        $query = $this->completedSessionsQuery($stationId);

        match ($period) {
            'daily' => $query->whereDate('session_ended_at', $this->dailySessionReferenceDate($year, $month)->toDateString()),
            'yearly' => $query->whereYear('session_ended_at', $year),
            default => $query->whereYear('session_ended_at', $year)->whereMonth('session_ended_at', $month),
        };

        $rows = $query
            ->leftJoin('packages', 'bookings.package_id', '=', 'packages.id')
            ->selectRaw('bookings.package_id, packages.name as package_name, COUNT(*) as sessions_count')
            ->groupBy('bookings.package_id', 'packages.name')
            ->orderByDesc('sessions_count')
            ->get();

        $total = (int) $rows->sum('sessions_count');

        if ($total <= 0) {
            return [];
        }

        $out = [];
        $index = 0;
        foreach ($rows as $row) {
            $count = (int) $row->sessions_count;
            $name = trim((string) $row->package_name) ?: 'غير محدد';
            $key = $row->package_id ? 'pkg-'.$row->package_id : 'unknown';

            $out[] = [
                'package_id' => $row->package_id ? (int) $row->package_id : null,
                'key' => $key,
                'name' => $name,
                'sessions_count' => $count,
                'percentage' => round(($count / $total) * 100, 1),
                'color' => $colors[$index % count($colors)],
            ];
            $index++;
        }

        return $out;
    }

    public function countCompletedSessionsForPeriod(int $stationId, int $year, int $month, string $period = 'monthly'): int
    {
        $query = $this->completedSessionsQuery($stationId);

        match ($period) {
            'daily' => $query->whereDate('session_ended_at', $this->dailySessionReferenceDate($year, $month)->toDateString()),
            'yearly' => $query->whereYear('session_ended_at', $year),
            default => $query->whereYear('session_ended_at', $year)->whereMonth('session_ended_at', $month),
        };

        return $query->count();
    }

    public function packageUsagePeriodLabel(int $year, int $month, string $period): string
    {
        $months = [
            'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
            'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
        ];

        return match ($period) {
            'daily' => $this->dailySessionReferenceDate($year, $month)->locale('ar')->translatedFormat('j F Y'),
            'yearly' => (string) $year,
            default => ($months[$month - 1] ?? (string) $month).' '.$year,
        };
    }

    private function completedSessionsQuery(int $stationId): Builder
    {
        return Booking::query()
            ->where('bookings.station_id', $stationId)
            ->where('bookings.booking_status', 'completed')
            ->where('bookings.session_status', 'finished')
            ->whereNotNull('bookings.session_ended_at');
    }

    private function dailySessionReferenceDate(int $year, int $month): Carbon
    {
        $daysInMonth = cal_days_in_month(CAL_GREGORIAN, $month, $year);
        $day = min(now()->day, $daysInMonth);

        return Carbon::create($year, $month, $day)->startOfDay();
    }

    public function countCompletedSessionsInMonth(int $stationId, int $year, int $month): int
    {
        return $this->countCompletedSessionsForPeriod($stationId, $year, $month, 'monthly');
    }

    public function sumExpensesInMonth(int $stationId, int $year, int $month): array
    {
        $items = $this->paidExpensesForStation($stationId)
            ->filter(fn (HallExpense $expense) => $this->expenseInMonth($expense, $year, $month))
            ->values();

        $total = (float) $items->sum(fn (HallExpense $expense) => (float) $expense->amount);

        return [
            'total' => round($total, 2),
            'count' => $items->count(),
        ];
    }

    public function sumExpensesInPrevMonth(int $stationId, int $year, int $month): array
    {
        $prevMonth = $month === 1 ? 12 : $month - 1;
        $prevYear = $month === 1 ? $year - 1 : $year;

        return $this->sumExpensesInMonth($stationId, $prevYear, $prevMonth);
    }

    /**
     * @return list<array{label: string, expenses: float}>
     */
    public function buildExpenseDailySeries(int $stationId, int $year, int $month): array
    {
        $days = cal_days_in_month(CAL_GREGORIAN, $month, $year);
        $buckets = array_fill(0, $days, 0.0);

        $expenses = $this->paidExpensesForStation($stationId);

        foreach ($expenses as $expense) {
            $ref = $this->expenseRecognitionDate($expense);
            if (! $ref || (int) $ref->year !== $year || (int) $ref->month !== $month) {
                continue;
            }

            $idx = (int) $ref->day - 1;
            if ($idx >= 0 && $idx < $days) {
                $buckets[$idx] += (float) $expense->amount;
            }
        }

        return collect($buckets)->map(function (float $amount, int $index) {
            return [
                'label' => (string) ($index + 1),
                'expenses' => round($amount, 2),
            ];
        })->all();
    }

    /**
     * @return list<array{name: string, key: string, value: float, color: string}>
     */
    public function buildExpenseCategoryBreakdown(int $stationId, int $year, int $month): array
    {
        $colors = ['#6B5478', '#3b82f6', '#f97316', '#eab308', '#22c55e', '#94a3b8', '#ec4899'];
        $map = [];

        $this->paidExpensesForStation($stationId)
            ->filter(fn (HallExpense $expense) => $this->expenseInMonth($expense, $year, $month))
            ->each(function (HallExpense $expense) use (&$map) {
                $key = $this->expenseBreakdownKey($expense);
                $map[$key] = ($map[$key] ?? 0) + (float) $expense->amount;
            });

        $out = [];
        $index = 0;
        foreach ($map as $key => $value) {
            $out[] = [
                'key' => $key,
                'name' => $key,
                'value' => round($value, 2),
                'color' => $colors[$index % count($colors)],
            ];
            $index++;
        }

        return $out;
    }

    /**
     * @return array<string, mixed>
     */
    public function buildOverview(int $stationId, int $year, int $month, string $granularity = 'daily', string $packagePeriod = 'monthly'): array
    {
        $revenueTotal = $this->sumRevenueInMonth($stationId, $year, $month);
        $prevMonth = $month === 1 ? 12 : $month - 1;
        $prevYear = $month === 1 ? $year - 1 : $year;
        $prevRevenue = $this->sumRevenueInMonth($stationId, $prevYear, $prevMonth);
        $revenueDelta = $prevRevenue > 0
            ? (($revenueTotal - $prevRevenue) / $prevRevenue) * 100
            : ($revenueTotal > 0 ? 100 : 0);

        $expenseTotals = $this->sumExpensesInMonth($stationId, $year, $month);
        $prevExpenseTotals = $this->sumExpensesInPrevMonth($stationId, $year, $month);
        $expenseDelta = $prevExpenseTotals['total'] > 0
            ? (($expenseTotals['total'] - $prevExpenseTotals['total']) / $prevExpenseTotals['total']) * 100
            : 0;

        $revenueSeries = match ($granularity) {
            'weekly' => $this->buildRevenueWeeklySeries($stationId, $year, $month),
            'monthly' => $this->buildRevenueMonthlySeries($stationId, $year),
            default => $this->buildRevenueDailySeries($stationId, $year, $month),
        };

        $expenseDaily = $this->buildExpenseDailySeries($stationId, $year, $month);
        $expenseSeries = $this->aggregateExpenseSeries($expenseDaily, $granularity, $month, $expenseTotals['total']);

        $profitSeries = collect($revenueSeries)->map(function (array $point, int $index) use ($expenseSeries) {
            $expenses = (float) ($expenseSeries[$index]['expenses'] ?? 0);
            $revenue = (float) $point['revenue'];

            return [
                'label' => $point['label'],
                'net_profit' => round($revenue - $expenses, 2),
            ];
        })->all();

        $netProfit = round($revenueTotal - $expenseTotals['total'], 2);
        $prevNet = round($prevRevenue - $prevExpenseTotals['total'], 2);
        $profitDelta = $prevNet != 0.0
            ? (($netProfit - $prevNet) / abs($prevNet)) * 100
            : ($netProfit > 0 ? 100 : 0);

        $monthRows = $this->recognizedRevenueRows($stationId)
            ->filter(fn (array $row) => $this->matchesMonth($row['recognized_at'], $year, $month));
        $platformCommissionTotal = round((float) $monthRows->sum('commission_amount'), 2);
        $grossRevenueTotal = round((float) $monthRows->sum('gross_amount'), 2);

        return [
            'year' => $year,
            'month' => $month,
            'granularity' => $granularity,
            'summary' => [
                'revenue' => round($revenueTotal, 2),
                'gross_revenue' => $grossRevenueTotal,
                'platform_commission' => $platformCommissionTotal,
                'revenue_delta' => round($revenueDelta, 2),
                'expenses' => round($expenseTotals['total'], 2),
                'expense_delta' => round($expenseDelta, 2),
                'net_profit' => $netProfit,
                'profit_delta' => round($profitDelta, 2),
            ],
            'revenue_series' => $revenueSeries,
            'expense_series' => $expenseSeries,
            'profit_series' => $profitSeries,
            'revenue_breakdown' => $this->buildRevenueSourceBreakdown($stationId, $year, $month),
            'expense_breakdown' => $this->buildExpenseCategoryBreakdown($stationId, $year, $month),
            'package_usage' => [
                'period' => $packagePeriod,
                'period_label' => $this->packageUsagePeriodLabel($year, $month, $packagePeriod),
                'total_sessions' => $this->countCompletedSessionsForPeriod($stationId, $year, $month, $packagePeriod),
                'breakdown' => $this->buildPackageUsageBreakdown($stationId, $year, $month, $packagePeriod),
            ],
            'sessions_count' => $this->countCompletedSessionsInMonth($stationId, $year, $month),
        ];
    }

    private function matchesMonth(Carbon $date, int $year, int $month): bool
    {
        return (int) $date->year === $year && (int) $date->month === $month;
    }

  /**
     * @return Collection<int, HallExpense>
     */
    private function paidExpensesForStation(int $stationId): Collection
    {
        return HallExpense::query()
            ->where('station_id', $stationId)
            ->where('is_paid', true)
            ->get();
    }

    private function countsTowardExpenses(HallExpense $expense): bool
    {
        return (bool) $expense->is_paid;
    }

    private function expenseRecognitionDate(HallExpense $expense): ?\Illuminate\Support\Carbon
    {
        if (! $this->countsTowardExpenses($expense)) {
            return null;
        }

        return $expense->paid_at ?? $expense->added_at;
    }

    private function expenseInMonth(HallExpense $expense, int $year, int $month): bool
    {
        $ref = $this->expenseRecognitionDate($expense);

        return $ref && (int) $ref->year === $year && (int) $ref->month === $month;
    }

    private function expenseBreakdownKey(HallExpense $expense): string
    {
        if ($expense->category === 'maintenance') {
            return 'الصيانة';
        }

        return trim($expense->name) ?: 'غير محدد';
    }

    /**
     * @param  list<array{label: string, expenses: float}>  $daily
     * @return list<array{label: string, expenses: float}>
     */
    private function aggregateExpenseSeries(array $daily, string $granularity, int $month, float $monthTotal): array
    {
        if ($granularity === 'daily') {
            return $daily;
        }

        if ($granularity === 'weekly') {
            $out = [];
            for ($week = 0; $week < 4; $week++) {
                $slice = array_slice($daily, $week * 7, 7);
                $out[] = [
                    'label' => 'الأسبوع '.($week + 1),
                    'expenses' => round(collect($slice)->sum('expenses'), 2),
                ];
            }

            return $out;
        }

        $months = [
            'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
            'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
        ];

        return collect($months)->map(function (string $name, int $index) use ($month, $monthTotal) {
            return [
                'label' => mb_substr($name, 0, 3),
                'expenses' => $index + 1 === $month ? round($monthTotal, 2) : 0.0,
            ];
        })->all();
    }
}
