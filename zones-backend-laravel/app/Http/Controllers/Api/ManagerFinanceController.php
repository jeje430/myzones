<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ResolvesManagerStation;
use App\Http\Controllers\Controller;
use App\Http\Resources\HallExpenseResource;
use App\Http\Resources\PaymentResource;
use App\Models\HallExpense;
use App\Models\Payment;
use App\Services\FinancialReportService;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ManagerFinanceController extends Controller
{
    use ResolvesManagerStation;

    public function __construct(
        private readonly FinancialReportService $reports,
    ) {}

    public function summary(Request $request): JsonResponse
    {
        $station = $this->resolveManagerStation($request->user());
        if (! $station) {
            return $this->managerStationMissingResponse();
        }

        $validated = $request->validate([
            'year' => 'nullable|integer|min:2000|max:2100',
            'month' => 'nullable|integer|min:1|max:12',
        ]);

        $year = (int) ($validated['year'] ?? now()->year);
        $month = (int) ($validated['month'] ?? now()->month);

        $overview = $this->reports->buildOverview($station->id, $year, $month, 'daily');

        return response()->json([
            'summary' => $overview['summary'],
            'sessions_count' => $overview['sessions_count'],
        ]);
    }

    public function overview(Request $request): JsonResponse
    {
        $station = $this->resolveManagerStation($request->user());
        if (! $station) {
            return $this->managerStationMissingResponse();
        }

        $validated = $request->validate([
            'year' => 'nullable|integer|min:2000|max:2100',
            'month' => 'nullable|integer|min:1|max:12',
            'granularity' => 'nullable|in:daily,weekly,monthly',
            'package_period' => 'nullable|in:daily,monthly,yearly',
        ]);

        $year = (int) ($validated['year'] ?? now()->year);
        $month = (int) ($validated['month'] ?? now()->month);
        $granularity = $validated['granularity'] ?? 'daily';
        $packagePeriod = $validated['package_period'] ?? 'monthly';

        return response()->json(
            $this->reports->buildOverview($station->id, $year, $month, $granularity, $packagePeriod),
        );
    }

    public function todayRevenue(Request $request): JsonResponse
    {
        $station = $this->resolveManagerStation($request->user());
        if (! $station) {
            return $this->managerStationMissingResponse();
        }

        return response()->json(
            $this->reports->todayRevenueSummary($station->id),
        );
    }

    public function payments(Request $request): JsonResponse
    {
        $station = $this->resolveManagerStation($request->user());
        if (! $station) {
            return $this->managerStationMissingResponse();
        }

        $validated = $request->validate([
            'payment_method' => 'nullable|in:electronic,pay_on_arrival',
            'date' => 'nullable|date_format:Y-m-d',
            'show_all' => 'nullable|boolean',
        ]);

        $query = Payment::query()
            ->where('status', 'completed')
            ->whereHas('booking', fn ($q) => $q->where('station_id', $station->id))
            ->with(['user', 'booking'])
            ->orderByDesc('paid_at')
            ->orderByDesc('id');

        if (! empty($validated['payment_method'])) {
            $query->where('payment_method', $validated['payment_method']);
        }

        $showAll = filter_var($request->input('show_all'), FILTER_VALIDATE_BOOLEAN);
        $filterDate = null;

        if (! $showAll) {
            $filterDate = $validated['date'] ?? Carbon::today()->toDateString();
            $query->whereDate('paid_at', $filterDate);
        }

        return response()->json([
            'payments' => PaymentResource::collection($query->get()),
            'filter' => [
                'date' => $filterDate,
                'show_all' => $showAll,
            ],
        ]);
    }
}
