<?php

require __DIR__.'/../vendor/autoload.php';

$app = require __DIR__.'/../bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use App\Services\BookingReceiptPdfService;

$service = app(BookingReceiptPdfService::class);

$types = [
    'regular' => [
        'booking_type' => 'regular',
        'station_name' => 'GS Game Plus',
        'booking_number' => 'BK-TEST-001',
        'customer_name' => 'Ahmed Ali',
        'booking_date' => '2026-06-21',
        'start_time' => '14:00',
        'end_time' => '16:00',
        'package_name' => 'PS5 - 2 Hours',
        'device_code' => 'PS5-001',
        'payment_method' => 'online',
        'amount' => 80,
    ],
    'offer' => [
        'booking_type' => 'offer',
        'station_name' => 'GS Game Plus',
        'booking_number' => 'BK-TEST-002',
        'customer_name' => 'Sara Mohamed',
        'booking_date' => '2026-06-21',
        'start_time' => '18:00',
        'end_time' => '20:00',
        'package_name' => 'VIP Package',
        'device_code' => 'PS5-002',
        'payment_method' => 'online',
        'amount_before_discount' => 100,
        'discount_percent' => 20,
        'amount_after_discount' => 80,
    ],
    'loyalty' => [
        'booking_type' => 'loyalty',
        'station_name' => 'GS Game Plus',
        'booking_number' => 'BK-TEST-003',
        'customer_name' => 'Khaled Omar',
        'booking_date' => '2026-06-21',
        'start_time' => '20:00',
        'end_time' => '22:00',
        'package_name' => 'Loyalty Session',
        'device_code' => 'PS5-003',
        'payment_method' => 'on_arrival',
        'loyalty_coupon_label' => 'Coupon',
        'loyalty_coupon_code' => 'LOYAL-100',
        'loyalty_points_per_session' => 10,
        'loyalty_points_total' => 100,
    ],
];

$dir = storage_path('app/public/receipts');
if (! is_dir($dir)) {
    mkdir($dir, 0777, true);
}

foreach ($types as $name => $payload) {
    $pdf = $service->generate($payload);
    $path = $dir.'/sample-'.$name.'.pdf';
    file_put_contents($path, $pdf->output());
    echo "Generated: {$path}\n";
}

echo "DONE\n";
