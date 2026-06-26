<?php

require __DIR__.'/../vendor/autoload.php';
$app = require __DIR__.'/../bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use App\Models\Booking;
use App\Models\PaymentTransaction;
use App\Services\FinancialReportService;

$codes = ['APP-001', 'APP-003', 'APP-014', 'APP-015', 'APP-016', 'APP-017'];
$service = app(FinancialReportService::class);

$bookings = Booking::query()
    ->whereIn('booking_number', $codes)
    ->orderBy('id')
    ->get();

$transactions = PaymentTransaction::query()
    ->whereIn('booking_id', $bookings->pluck('id'))
    ->get()
    ->keyBy('booking_id');

$rows = [];
$total = 0;

foreach ($bookings as $b) {
    $t = $transactions->get($b->id);
    $recognized = $service->revenueRecognizedAt($b);
    $amount = (float) $b->total_price;
    $total += $amount;

    $rows[] = [
        'id' => $b->id,
        'booking_number' => $b->booking_number,
        'station_id' => $b->station_id,
        'user_id' => $b->user_id,
        'visitor_name' => $b->visitor_name,
        'booking_type' => $b->booking_type,
        'start_date' => $b->start_date?->format('Y-m-d'),
        'start_time' => $b->start_time,
        'end_time' => $b->end_time,
        'hours_count' => $b->hours_count,
        'original_hourly_price' => (float) $b->original_hourly_price,
        'discounted_hourly_price' => (float) $b->discounted_hourly_price,
        'subtotal_price' => (float) $b->subtotal_price,
        'discount_amount' => (float) $b->discount_amount,
        'total_price' => $amount,
        'payment_method' => $b->payment_method,
        'payment_status' => $b->payment_status,
        'booking_status' => $b->booking_status,
        'session_status' => $b->session_status,
        'is_checked_in' => (bool) $b->is_checked_in,
        'checked_in_at' => $b->checked_in_at?->toDateTimeString(),
        'booking_source' => $b->booking_source,
        'created_at' => $b->created_at?->toDateTimeString(),
        'updated_at' => $b->updated_at?->toDateTimeString(),
        'recognized_at' => $recognized?->toDateTimeString(),
        'payment_transaction' => $t ? [
            'invoice_no' => $t->invoice_no,
            'amount' => (float) $t->amount,
            'status' => $t->status,
            'paid_at' => $t->paid_at?->toDateTimeString(),
        ] : null,
    ];
}

echo json_encode([
    'bookings' => $rows,
    'count' => count($rows),
    'total_price_sum' => $total,
], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
echo PHP_EOL;
