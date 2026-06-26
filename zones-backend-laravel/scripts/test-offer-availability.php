<?php

require __DIR__.'/../vendor/autoload.php';

$app = require __DIR__.'/../bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$offer = App\Models\Offer::query()
    ->with(['station', 'package'])
    ->whereNotNull('station_id')
    ->whereNotNull('package_id')
    ->where('is_active', true)
    ->first();

if (! $offer) {
    echo "NO_ACTIVE_OFFER\n";
    exit(0);
}

echo "offer_id={$offer->id} station={$offer->station_id} package={$offer->package_id}\n";

$date = now()->format('Y-m-d');
$service = app(App\Services\BookingAvailabilityService::class);
$result = $service->slotsForPackage($offer->station, $offer->package, $date, $offer);

echo 'available='.($result['available'] ? 'yes' : 'no').' slots='.count($result['slots'])."\n";
echo 'message='.($result['message'] ?? 'null')."\n";

if (! empty($result['slots'][0])) {
    echo json_encode($result['slots'][0], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE)."\n";
}
