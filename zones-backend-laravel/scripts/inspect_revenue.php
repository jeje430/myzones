<?php

require __DIR__.'/../vendor/autoload.php';
$app = require __DIR__.'/../bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use App\Models\Booking;
use App\Services\FinancialReportService;

$service = app(FinancialReportService::class);

echo "=== ALL bookings station 1 ===\n";
foreach (Booking::where('station_id', 1)->orderBy('id')->get() as $b) {
    $recognized = $service->revenueRecognizedAt($b);
  $counts = in_array($b->booking_type, ['regular','offer'], true)
    && $b->payment_status === 'paid'
    && !in_array($b->booking_status, ['cancelled','cancelled_maintenance'], true);
    echo implode(' | ', [
        $b->id,
        $b->booking_number,
        $b->total_price,
        $b->payment_method,
        $b->payment_status,
        $b->booking_type,
        $b->booking_status,
        'recognized='.($recognized?->format('Y-m-d H:i') ?? 'null'),
        $counts ? 'COUNTED' : 'skip',
    ])."\n";
}

echo "\nRecognized rows June 2026:\n";
foreach ($service->recognizedRevenueRows(1) as $row) {
    if ($row['recognized_at']->month === 6 && $row['recognized_at']->year === 2026) {
        echo $row['booking']->booking_number.' = '.$row['amount'].' on '.$row['recognized_at']->toDateString()."\n";
    }
}

echo "\nMonth sum station 1: ".$service->sumRevenueInMonth(1, 2026, 6)."\n";
